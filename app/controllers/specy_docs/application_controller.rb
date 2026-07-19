# frozen_string_literal: true

module SpecyDocs
  class ApplicationController < ActionController::Base
    # Docs UI is read-only static assets + JSON; CSRF / same-origin JS checks
    # block <script src> loads when serving application/javascript via the controller.
    skip_forgery_protection
  end
end
