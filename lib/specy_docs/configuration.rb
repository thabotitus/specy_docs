# frozen_string_literal: true

module SpecyDocs
  class Configuration
    attr_accessor :capture_path,
                  :report_path,
                  :masked_header_keys,
                  :title,
                  :eyebrow,
                  :opt_in,
                  :capture_paths

    def initialize
      @capture_path = nil
      @report_path = nil
      @masked_header_keys = []
      @title = 'API Docs'
      @eyebrow = 'specy-docs'
      @opt_in = true
      @capture_paths = []
    end

    def resolved_capture_path
      Pathname(capture_path || Rails.root.join('tmp/specy_docs/captures.json'))
    end

    def resolved_report_path
      Pathname(report_path || Rails.root.join('tmp/specy_docs/report.json'))
    end
  end
end
