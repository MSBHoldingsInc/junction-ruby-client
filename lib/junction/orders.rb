# frozen_string_literal: true

module Junction
  class Orders
    ENDPOINT = '/v3/order'

    # Create or submit order
    # POST /v3/order
    # https://docs.junction.com/api-reference/lab-testing/create-order
    # https://docs.junction.com/lab/overview/idempotency
    # @param body [Hash]
    # @param idempotency_key [String]
    # @return [Hash]
    def self.create(body:, idempotency_key:)
      Client.post(ENDPOINT, body, { 'X-Idempotency-Key' => idempotency_key })
    end

    # Retrieve order
    # GET /v3/order/{order_id}
    # https://docs.junction.com/api-reference/lab-testing/get-order
    # @param order_id [String]
    # @return [Hash]
    def self.find(order_id)
      Client.get("#{ENDPOINT}/#{order_id}")
    end

    # Retrieve requisition PDF
    # GET /v3/order/{order_id}/requisition/pdf
    # https://docs.junction.com/api-reference/lab-testing/requisition-pdf
    # @param order_id [String]
    # @return [String] raw PDF bytes
    def self.requisition_pdf(order_id)
      Client.get("#{ENDPOINT}/#{order_id}/requisition/pdf", {}, { 'Accept' => 'application/pdf' })
    end
  end
end
