# frozen_string_literal: true

require 'junction'
require 'webmock/rspec'

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!

  config.before do
    Junction.reset_configuration!
    Junction.configure do |c|
      c.api_key  = 'test-key'
      c.base_uri = 'https://api.sandbox.us.junction.com'
    end
  end
end
