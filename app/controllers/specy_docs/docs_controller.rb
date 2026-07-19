# frozen_string_literal: true

module SpecyDocs
  class DocsController < ApplicationController
    layout false
    skip_after_action :verify_same_origin_request, only: %i[javascript stylesheet]

    def show
      @config = SpecyDocs.configuration
    end

    def report
      path = SpecyDocs.configuration.resolved_report_path
      if path.exist?
        send_file path, type: 'application/json', disposition: 'inline'
      else
        render json: {}
      end
    end

    def javascript
      send_frontend('app.js', 'application/javascript')
    end

    def stylesheet
      send_frontend('styles.css', 'text/css')
    end

    private

    def send_frontend(filename, content_type)
      file = SpecyDocs::Engine.root.join('app/frontend', filename)
      raise ActionController::RoutingError, 'Not Found' unless file.exist?

      send_file file, type: content_type, disposition: 'inline'
    end
  end
end
