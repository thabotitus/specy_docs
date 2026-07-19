# frozen_string_literal: true

require 'specy_docs/version'
require 'specy_docs/configuration'
require 'specy_docs/capturable'
require 'specy_docs/report_generator'
require 'specy_docs/engine'

module SpecyDocs
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    # Install Capturable into RSpec.
    # When +capture_paths+ is configured, includes by file path so specs without
    # +type: :request+ (e.g. legacy controller specs) can still be captured.
    # Otherwise includes for +type: :request+ only.
    def setup_rspec(rspec_config)
      paths = Array(configuration.capture_paths).map(&:to_s).reject(&:empty?)

      if paths.empty?
        rspec_config.include Capturable, type: :request
      else
        rspec_config.include Capturable, file_path: capture_paths_pattern(paths)
      end
    end

    def capture_paths_pattern(paths = configuration.capture_paths)
      Regexp.union(
        Array(paths).map(&:to_s).reject(&:empty?).map do |path|
          escaped = Regexp.escape(path.sub(%r{\A\./}, '').delete_suffix('/'))
          %r{(?:\A|/|\./)#{escaped}/}
        end
      )
    end
  end
end
