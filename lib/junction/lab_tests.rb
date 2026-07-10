# frozen_string_literal: true

module Junction
  class LabTests
    PAGE_SIZE = 100

    # Retrieve all markers for a lab test across every page
    # GET /v3/lab_tests/{lab_test_id}/markers
    # https://docs.junction.com/api-reference/lab-testing/lab-test-markers
    # @param lab_test_id [String]
    # @return [Array<Hash>]
    def self.markers(lab_test_id)
      markers = []
      page = 1

      loop do
        response = Client.get("/v3/lab_tests/#{lab_test_id}/markers", { page: page, size: PAGE_SIZE })
        markers.concat(response.fetch('markers', []))

        break if response['page'] == response['pages']

        page += 1
      end

      markers
    end
  end
end
