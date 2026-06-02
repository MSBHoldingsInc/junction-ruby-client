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

    # Retrieve order
    # https://docs.junction.com/api-reference/lab-testing/get-order
    # @param order_id [String]
    # @return [Hash]
    def self.find(order_id)
      Client.get("#{ENDPOINT}/#{order_id}")
    end

    # Retrieve requisition PDF
    # https://docs.junction.com/api-reference/lab-testing/requisition-pdf
    # @param order_id [String]
    # @return [String] raw PDF bytes
    def self.requisition_pdf(order_id)
      Client.get("#{ENDPOINT}/#{order_id}/requisition/pdf", {}, { 'Accept' => 'application/pdf' })
    end

    # Retrieve lab results as structured data
    # https://docs.junction.com/api-reference/lab-testing/results/get-results
    # @param order_id [String]
    # @return [Hash]
    def self.results(order_id)
      Client.get("#{ENDPOINT}/#{order_id}/result")
    end

    # Retrieve lab results PDF
    # https://docs.junction.com/api-reference/lab-testing/results/get-results-pdf
    # @param order_id [String]
    # @return [String] raw PDF bytes
    def self.results_pdf(order_id)
      Client.get("#{ENDPOINT}/#{order_id}/result/pdf", {}, { 'Accept' => 'application/pdf' })
    end
  end
end
