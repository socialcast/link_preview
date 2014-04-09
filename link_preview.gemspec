$:.push File.expand_path('../lib', __FILE__)

require 'link_preview/version'

Gem::Specification.new do |s|
  s.name        = 'link_preview'
  s.version     = LinkPreview::VERSION
  s.authors     = ['Michael Andrews']
  s.email       = ['michael@socialcast.com']
  s.homepage    = 'https://github.com/socialcast/link_preview'
  s.summary     = 'Generate a link_preview for any URL'
  s.description = 'Generate a link_preview for any URL'

  s.files = Dir['{lib,spec/support/link_preview}/**/*'] + ['LICENSE.txt', 'Rakefile', 'README.md']
  s.test_files = Dir['spec/**/*']

  s.add_dependency('ruby-oembed')
  s.add_dependency('addressable')
  s.add_dependency('faraday', '~> 0.9.0')
  s.add_dependency('nokogiri')
  s.add_dependency('multi_json')

  s.add_dependency('activesupport')

  # Development
  s.add_development_dependency('rake')

  # Testing
  s.add_development_dependency('rspec')
  s.add_development_dependency('vcr')
  s.add_development_dependency('webmock')
  s.add_development_dependency('debugger')
end
