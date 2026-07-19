# frozen_string_literal: true

require_relative 'lib/specy_docs/version'

Gem::Specification.new do |spec|
  spec.name          = 'specy_docs'
  spec.version       = SpecyDocs::VERSION
  spec.authors       = ['Thabo Titus']
  spec.email         = ['hello@thabotitus.co.za']

  spec.summary       = 'Mountable API docs generated from RSpec request captures'
  spec.description   = 'Capture request/response examples from RSpec request specs and serve ' \
                       'a browsable docs UI from a mountable Rails engine.'
  spec.homepage      = 'https://github.com/thabotitus/specy_docs'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/thabotitus/specy_docs'
  spec.metadata['changelog_uri'] = 'https://github.com/thabotitus/specy_docs/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(__dir__) do
    Dir['{app,config,lib}/**/*', 'MIT-LICENSE', 'README.md']
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 7.0'
end
