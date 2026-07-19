# frozen_string_literal: true

require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'

module SpecyDocs
  class Engine < ::Rails::Engine
    isolate_namespace SpecyDocs

    rake_tasks do
      load File.expand_path('tasks/specy_docs_tasks.rake', __dir__)
    end
  end
end
