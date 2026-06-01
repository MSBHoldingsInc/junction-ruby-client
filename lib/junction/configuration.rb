# frozen_string_literal: true

module Junction
  # Runtime configuration for the Junction API client. Set once at boot, e.g.
  # in a Rails initializer:
  #
  #   Junction.configure do |c|
  #     c.api_key  = ENV.fetch('JUNCTION_API_KEY')
  #     c.base_uri = 'https://api.us.junction.com'
  #   end
  class Configuration
    attr_accessor :api_key, :base_uri

    def initialize
      @base_uri = 'https://api.sandbox.us.junction.com'
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    # Resets configuration to defaults. Primarily useful in tests.
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
