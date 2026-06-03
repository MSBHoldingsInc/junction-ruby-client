# frozen_string_literal: true

module Junction
  class LabResults
    # Retrieve lab results as structured data
    # GET /v3/order/{order_id}/result
    # https://docs.junction.com/api-reference/lab-testing/results/get-results
    # @param order_id [String]
    # @return [Hash]
    def self.find(order_id)
      Client.get("#{Orders::ENDPOINT}/#{order_id}/result")
    end

    # Retrieve lab results PDF
    # GET /v3/order/{order_id}/result/pdf
    # https://docs.junction.com/api-reference/lab-testing/results/get-results-pdf
    # @param order_id [String]
    # @return [String] raw PDF bytes
    def self.pdf(order_id)
      Client.get("#{Orders::ENDPOINT}/#{order_id}/result/pdf", {}, { 'Accept' => 'application/pdf' })
    end
  end
end
