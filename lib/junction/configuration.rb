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
    # Timeout defaults, in seconds. Deliberately much tighter than Net::HTTP's
    # 60s so a slow or unresponsive Junction API fails fast rather than tying up
    # the calling process (a Rails request, a Sidekiq worker) for a full minute.
    DEFAULT_OPEN_TIMEOUT = 5
    DEFAULT_READ_TIMEOUT = 15
    DEFAULT_WRITE_TIMEOUT = 10

    attr_accessor :api_key, :base_uri

    # Seconds to wait for the TCP/TLS connection to be established.
    # Set to +nil+ to fall back to the Net::HTTP default.
    # @return [Numeric, nil]
    attr_accessor :open_timeout

    # Seconds to wait for a response once the request has been sent.
    # Set to +nil+ to fall back to the Net::HTTP default.
    # @return [Numeric, nil]
    attr_accessor :read_timeout

    # Seconds to wait while writing the request body.
    # Set to +nil+ to fall back to the Net::HTTP default.
    # @return [Numeric, nil]
    attr_accessor :write_timeout

    def initialize
      @base_uri = 'https://api.sandbox.us.junction.com'
      @open_timeout = DEFAULT_OPEN_TIMEOUT
      @read_timeout = DEFAULT_READ_TIMEOUT
      @write_timeout = DEFAULT_WRITE_TIMEOUT
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
