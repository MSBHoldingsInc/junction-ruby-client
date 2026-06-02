# frozen_string_literal: true

module Junction
  class Orders
    ENDPOINT = '/v3/order'

    # Create or submit order
    # https://docs.junction.com/api-reference/lab-testing/create-order
    # @param body [Hash]
    # @return [Hash]
    def self.create(body = {})
      Client.post(ENDPOINT, body)
    end
  end
end