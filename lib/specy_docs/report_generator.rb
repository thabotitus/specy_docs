# frozen_string_literal: true

require 'fileutils'
require 'json'

module SpecyDocs
  class ReportGenerator
    class InvalidCaptureFileError < StandardError; end

    HTTP_METHODS = %w[get put post delete].freeze

    def self.call(capture_file: nil, output_file: nil)
      new(
        capture_file: capture_file || SpecyDocs.configuration.resolved_capture_path,
        output_file: output_file || SpecyDocs.configuration.resolved_report_path
      ).call
    end

    def initialize(capture_file:, output_file:)
      @capture_file = Pathname(capture_file)
      @output_file = Pathname(output_file)
    end

    def call
      report = build_report
      write_report(report)
      report
    end

    private

    attr_reader :capture_file, :output_file

    def build_report
      return {} unless capture_file.exist?

      grouped_captures = captures.each_value.with_object({}) do |capture, grouped|
        path = capture.dig('request', 'path')
        method = capture.dig('request', 'method')&.downcase
        next unless path.present? && HTTP_METHODS.include?(method)

        template = route_template(path, method)
        grouped[template] ||= HTTP_METHODS.index_with { [] }
        grouped[template][method] << capture
      end

      grouped_captures.sort.to_h
    end

    def write_report(report)
      FileUtils.mkdir_p(output_file.dirname)
      File.write(output_file, JSON.pretty_generate(report))
    end

    def captures
      JSON.parse(capture_file.read)
    rescue JSON::ParserError => e
      raise InvalidCaptureFileError, "Invalid capture file: #{e.message}"
    end

    # Resolves a concrete path to its Rails route template via the route's path.spec.
    # Domain-like params with dots are matched as [^/]+ so (.:format) does not steal TLDs.
    def route_template(path, method)
      route = Rails.application.routes.routes.find do |candidate|
        next if catch_all_route?(candidate)
        next unless verb_matches?(candidate, method)

        path_matches_template?(path, candidate)
      end

      return path unless route

      strip_optional_format(route.path.spec.to_s)
    end

    def verb_matches?(route, method)
      verb = route.verb
      verb.blank? || verb.match?(method.upcase)
    end

    def path_matches_template?(path, route)
      template = strip_optional_format(route.path.spec.to_s)
      pattern = template.split('/').map do |segment|
        segment.start_with?(':') ? '[^/]+' : Regexp.escape(segment)
      end.join('/')

      /\A#{pattern}\z/.match?(path)
    end

    def strip_optional_format(spec)
      spec.sub(/\(\.:format\)\z/, '')
    end

    def catch_all_route?(route)
      route.path.spec.to_s.include?('*')
    end
  end
end
