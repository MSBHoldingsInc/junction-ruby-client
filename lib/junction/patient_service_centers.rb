# frozen_string_literal: true

module Junction
  class PatientServiceCenters
    # Default search radius (miles) for patient service center / lab lookups.
    DEFAULT_RADIUS_MILES = 25

    # Retrieve lab/area coverage for a ZIP code
    # GET /v3/order/area/info
    # https://docs.junction.com/api-reference/lab-testing/area-info
    # @param zip_code [String]
    # @param radius [Integer] search radius in miles (defaults to {DEFAULT_RADIUS_MILES})
    # @return [Hash]
    def self.coverage(zip_code, radius: DEFAULT_RADIUS_MILES)
      Client.get("#{Orders::ENDPOINT}/area/info", { zip_code: zip_code, radius: radius })
    end

    # Retrieve patient service centers near a ZIP code for a given lab
    # GET /v3/order/psc/info
    # https://docs.junction.com/api-reference/lab-testing/psc-info
    # @param zip_code [String]
    # @param lab_id [Integer]
    # @param radius [Integer] search radius in miles (defaults to {DEFAULT_RADIUS_MILES})
    # @return [Hash]
    def self.near(zip_code, lab_id:, radius: DEFAULT_RADIUS_MILES)
      Client.get("#{Orders::ENDPOINT}/psc/info", { zip_code: zip_code, lab_id: lab_id, radius: radius })
    end

    # Retrieve patient service centers available for an existing order
    # GET /v3/order/{order_id}/psc/info
    # https://docs.junction.com/api-reference/lab-testing/order-psc-info
    # @param order_id [String]
    # @param radius [Integer] search radius in miles (defaults to {DEFAULT_RADIUS_MILES})
    # @return [Hash]
    def self.for_order(order_id, radius: DEFAULT_RADIUS_MILES)
      Client.get("#{Orders::ENDPOINT}/#{order_id}/psc/info", { radius: radius })
    end
  end
end
