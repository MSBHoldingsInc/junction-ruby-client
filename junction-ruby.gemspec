# frozen_string_literal: true

require_relative 'lib/junction/version'

Gem::Specification.new do |spec|
  spec.name        = 'junction-ruby'
  spec.version     = Junction::VERSION
  spec.authors     = ['Seth Goodwin']
  spec.email       = ['seth.goodwin@rugiet.com']

  spec.summary     = 'Ruby client for the Junction (formerly Vital) API'
  spec.description  = 'A small HTTParty-based wrapper around the Junction/Vital API.'
  spec.homepage    = 'https://github.com/msb/junction-ruby' # TODO: update to the real repo URL
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*.rb', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'httparty', '>= 0.21.0'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
