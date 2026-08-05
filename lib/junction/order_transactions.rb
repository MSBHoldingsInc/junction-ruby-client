# frozen_string_literal: true

module Junction
  class OrderTransactions
    ENDPOINT = '/v3/order_transaction'

    # Retrieve order transaction
    # GET /v3/order_transaction/{transaction_id}
    # https://docs.junction.com/api-reference/lab-testing/order-transactions/get-order-transaction
    # @param transaction_id [String]
    # @return [Hash]
    def self.find(transaction_id)
      Client.get("#{ENDPOINT}/#{transaction_id}")
    end

    # Retrieve order transaction result
    # GET /v3/order_transaction/{transaction_id}/result
    # https://docs.junction.com/api-reference/lab-testing/results/get-order-transaction-results
    # @param transaction_id [String]
    # @return [Hash]
    def self.results(transaction_id)
      Client.get("#{ENDPOINT}/#{transaction_id}/result")
    end

    # Retrieve order transaction result PDF
    # GET /v3/order_transaction/{transaction_id}/result/pdf
    # https://docs.junction.com/api-reference/lab-testing/results/get-order-transaction-results-pdf
    # @param transaction_id [String]
    # @return [String] raw PDF bytes
    def self.results_pdf(transaction_id)
      Client.get("#{ENDPOINT}/#{transaction_id}/result/pdf", {}, { 'Accept' => 'application/pdf' })
    end
  end
end
