# frozen_string_literal: true

module Junction
  # Thin HTTP layer over the Junction (Vital) API. Owns auth, base URL, JSON (de)serialization, and error handling.
  class Client
    include HTTParty

    class RequestError < StandardError
      attr_reader :response

      def initialize(message, response: nil)
        super(message)
        @response = response
      end
    end

    class << self
      def get(endpoint, query = {})
        handle_response(super(url(endpoint), query: query, headers: headers))
      end

      def post(endpoint, body = {})
        handle_response(super(url(endpoint), body: body.to_json, headers: headers))
      end

      def patch(endpoint, body = {})
        handle_response(super(url(endpoint), body: body.to_json, headers: headers))
      end

      private

      # Build a full URL from config at request time. Passing a complete URL
      # (rather than relying on HTTParty's `base_uri` class macro) keeps the
      # base URL configurable at runtime instead of frozen at load time.
      def url(endpoint)
        "#{Junction.configuration.base_uri}#{endpoint}"
      end

      def headers
        {
          'Accept'          => 'application/json',
          'Content-Type'    => 'application/json',
          'x-vital-api-key' => Junction.configuration.api_key
        }
      end

      def handle_response(response)
        return response.parsed_response if response.success?

        raise RequestError.new("Junction API #{response.code}: #{response.body}", response: response)
      end
    end
  end
end
