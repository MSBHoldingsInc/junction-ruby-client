# frozen_string_literal: true

require_relative 'lib/junction/version'

Gem::Specification.new do |spec|
  spec.name        = 'junction-ruby-client'
  spec.version     = Junction::VERSION
  spec.authors     = ['Seth Goodwin']
  spec.email       = ['seth.goodwin@rugiet.com']

  spec.summary     = 'Ruby client for the Junction (formerly Vital) API'
  spec.description = 'A small HTTParty-based wrapper around the Junction/Vital API.'
  spec.homepage    = 'https://github.com/MSBHoldingsInc/junction-ruby-client'
  spec.license     = 'Nonstandard' # proprietary; internal use only, not for public distribution
  spec.required_ruby_version = '>= 3.0'

  # Private gem: consumed by other org repos directly from git, never published
  # to a registry. 'none' makes `gem push` refuse, guarding against an
  # accidental public release.
  spec.metadata['allowed_push_host'] = 'none'
  spec.metadata['source_code_uri']   = 'https://github.com/MSBHoldingsInc/junction-ruby-client'

  spec.files         = Dir['lib/**/*.rb', 'README.md', 'LICENSE']
  spec.require_paths = ['lib']

  # Core dependencies
  spec.add_dependency 'httparty', '>= 0.21.0'

  # Development dependencies
  spec.add_development_dependency 'dotenv', '~> 3.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
