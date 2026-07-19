# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'digest'

module SpecyDocs
  module Capturable
    def self.included(base)
      base.after(:each) do |example|
        next unless SpecyDocs::Capturable.should_capture?(example)
        next unless defined?(response) && response.present?

        SpecyDocs::Capturable.record(example, request, response)
      end
    end

    def self.should_capture?(example)
      return false unless matches_capture_path?(example)

      if SpecyDocs.configuration.opt_in
        !!example.metadata[:specy]
      else
        example.metadata[:specy] != false
      end
    end

    def self.matches_capture_path?(example)
      configured = Array(SpecyDocs.configuration.capture_paths).map(&:to_s).reject(&:empty?)
      return true if configured.empty?

      file_path = example.metadata[:absolute_file_path].presence || example.metadata[:file_path]
      return false if file_path.blank?

      absolute = Pathname(file_path).expand_path.to_s

      configured.any? do |capture_path|
        base = Pathname(capture_path)
        base = Rails.root.join(capture_path) unless base.absolute?
        prefix = "#{base.expand_path}#{File::SEPARATOR}"
        absolute == base.expand_path.to_s || absolute.start_with?(prefix)
      end
    end

    def self.record(example, request, response)
      capture_file = SpecyDocs.configuration.resolved_capture_path
      FileUtils.mkdir_p(capture_file.dirname)

      key = example.id
      captures = load_captures(capture_file)
      captures[key] = {
        description: example.full_description,
        location: "#{example.metadata[:file_path]}:#{example.metadata[:line_number]}",
        request: {
          method: request.request_method,
          path: request.path,
          query_string: request.query_string.presence,
          headers: filtered_headers(request),
          body: raw_body(request)
        },
        response: {
          status: response.status,
          headers: response.headers.slice('Content-Type', 'Location'),
          body: parsed_body(response)
        },
        captured_at: Time.current.iso8601
      }

      File.write(capture_file, JSON.pretty_generate(captures))
    end

    def self.load_captures(capture_file = SpecyDocs.configuration.resolved_capture_path)
      return {} unless capture_file.exist?

      JSON.parse(File.read(capture_file))
    rescue JSON::ParserError
      {}
    end

    def self.raw_body(request)
      request_body = request.body
      return nil unless request_body

      body = request_body.read
      request_body.rewind
      body.presence
    end

    def self.filtered_headers(request)
      request.headers.env
             .select { |k, _| k.start_with?('HTTP_') || k == 'CONTENT_TYPE' }
    end

    def self.parsed_body(response)
      return nil if response.body.blank?

      JSON.parse(response.body)
    rescue JSON::ParserError
      response.body
    end
  end
end
