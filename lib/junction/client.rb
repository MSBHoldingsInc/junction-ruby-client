# frozen_string_literal: true

module Junction
  # Thin HTTP layer over the Junction (Vital) API. Owns auth, base URL, JSON (de)serialization, and error handling.
  class Client
    include HTTParty

    # Serialize array query params as repeated keys (`site_codes=a&site_codes=b`)
    # rather than HTTParty's default `site_codes[]=a`, which the Junction API
    # does not recognize (the bracketed form is silently dropped).
    query_string_normalizer HTTParty::Request::NON_RAILS_QUERY_STRING_NORMALIZER

    # Raised on any non-2xx Junction response. Carries the raw HTTParty response so
    # callers can branch on the status code and the parsed +detail+ Junction returns.
    class RequestError < StandardError
      # @return [HTTParty::Response, nil] the raw response, when available
      attr_reader :response

      # @param message [String] the error message (includes status and raw body)
      # @param response [HTTParty::Response, nil] the failing response
      def initialize(message, response: nil)
        super(message)
        @response = response
      end

      # @return [Integer, nil] the HTTP status code Junction returned
      def status
        response&.code
      end

      # Extracts Junction's human-readable +detail+. Business-logic errors return a
      # string ({"detail": "..."}); validation errors return a list of FastAPI entries
      # ({"detail": [{"loc":..., "msg":...}]}), whose +msg+ values are joined.
      # @return [String, nil]
      def detail
        body = response&.parsed_response
        return nil unless body.is_a?(Hash)

        value = body['detail']
        presence(value.is_a?(Array) ? join_messages(value) : value)
      end

      private

      # @param entries [Array] FastAPI validation entries (or bare strings)
      # @return [String] the entries' +msg+ values joined with "; "
      def join_messages(entries)
        entries.filter_map { |e| e.is_a?(Hash) ? e['msg'] : e }.join('; ')
      end

      # @param value [Object] a candidate detail value
      # @return [String, nil] the value when it is a non-blank string, else nil
      def presence(value)
        return nil unless value.is_a?(String)

        value.strip.empty? ? nil : value
      end
    end

    class << self
      def get(endpoint, query = {}, custom_headers = {})
        handle_response(super(url(endpoint), query: query, headers: default_headers.merge(custom_headers)))
      end

      def post(endpoint, body = {}, custom_headers = {}, query = {})
        handle_response(
          super(url(endpoint), body: body.to_json, query: query, headers: default_headers.merge(custom_headers))
        )
      end

      def patch(endpoint, body = {}, custom_headers = {})
        handle_response(super(url(endpoint), body: body.to_json, headers: default_headers.merge(custom_headers)))
      end

      private

      # Build a full URL from config at request time. Passing a complete URL
      # (rather than relying on HTTParty's `base_uri` class macro) keeps the
      # base URL configurable at runtime instead of frozen at load time.
      def url(endpoint)
        "#{Junction.configuration.base_uri}#{endpoint}"
      end

      def default_headers
        {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
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
