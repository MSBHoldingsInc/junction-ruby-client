# frozen_string_literal: true

module Junction
  # Patient Service Center (PSC) appointment scheduling for Quest locations whose
  # capabilities include `appointment_scheduling_via_junction`.
  # https://docs.junction.com/lab/overview/locations#appointment-scheduling-capability
  class Appointments
    ENDPOINT = '/v3/order'

    # Default availability search radius in miles; one of 10/20/25/50/100.
    DEFAULT_RADIUS_MILES = 25

    # Find available appointment slots
    # POST /v3/order/psc/appointment/availability
    # https://docs.junction.com/api-reference/lab-testing/psc-scheduling/appointment-psc-availability
    # The API requires at least one of +zip_code+ or +site_codes+. A +zip_code+
    # (with +radius+) runs a geo search returning up to three nearby PSCs and
    # overrides +site_codes+; pass +site_codes+ alone (omit +zip_code+) to scope
    # to exactly those PSCs.
    # @param lab [String] required, "quest" or "sonora_quest"
    # @param zip_code [String, nil] 5-digit ZIP for a geo search; omit when scoping by +site_codes+
    # @param radius [Integer, String, nil] 10/20/25/50/100 (defaults to {DEFAULT_RADIUS_MILES})
    # @param options [Hash] optional filters: +site_codes+ (Array<String>), +start_date+ (YYYY-MM-DD), +allow_stale+
    # @return [Hash]
    def self.availability(lab:, zip_code: nil, radius: DEFAULT_RADIUS_MILES, **options)
      query = { lab: lab, zip_code: zip_code, radius: radius&.to_s, **options }.compact

      Client.post("#{ENDPOINT}/psc/appointment/availability", {}, {}, query)
    end

    # Book an appointment for an order
    # POST /v3/order/{order_id}/psc/appointment/book
    # https://docs.junction.com/api-reference/lab-testing/psc-scheduling/appointment-psc-booking
    # @param order_id [String] required
    # @param booking_key [String] required, from {.availability}
    # @param options [Hash] optional body fields, e.g. +appointment_notes+ (max 1000 chars)
    # @return [Hash]
    def self.book(order_id, booking_key:, **options)
      body = { booking_key: booking_key, **options }.compact

      Client.post("#{ENDPOINT}/#{order_id}/psc/appointment/book", body)
    end

    # Reschedule an order's appointment to a new slot
    # PATCH /v3/order/{order_id}/psc/appointment/reschedule
    # https://docs.junction.com/api-reference/lab-testing/psc-scheduling/appointment-psc-rescheduling
    # @param order_id [String] required
    # @param booking_key [String] required, from {.availability}
    # @param options [Hash] optional body fields, e.g. +appointment_notes+ (max 1000 chars)
    # @return [Hash]
    def self.reschedule(order_id, booking_key:, **options)
      body = { booking_key: booking_key, **options }.compact

      Client.patch("#{ENDPOINT}/#{order_id}/psc/appointment/reschedule", body)
    end

    # Cancel an order's appointment
    # PATCH /v3/order/{order_id}/psc/appointment/cancel
    # https://docs.junction.com/api-reference/lab-testing/psc-scheduling/appointment-psc-cancelling
    # @param order_id [String] required
    # @param cancellation_reason_id [String] required, an id from {.cancellation_reasons}
    # @param options [Hash] optional body fields, e.g. +note+
    # @return [Hash]
    def self.cancel(order_id, cancellation_reason_id:, **options)
      body = { cancellation_reason_id: cancellation_reason_id, **options }.compact

      Client.patch("#{ENDPOINT}/#{order_id}/psc/appointment/cancel", body)
    end

    # Retrieve an order's appointment
    # GET /v3/order/{order_id}/psc/appointment
    # https://docs.junction.com/api-reference/lab-testing/psc-scheduling/get-appointment
    # @param order_id [String] required
    # @return [Hash]
    def self.find(order_id)
      Client.get("#{ENDPOINT}/#{order_id}/psc/appointment")
    end

    # List the available cancellation reasons (use an id with {.cancel})
    # GET /v3/order/psc/appointment/cancellation-reasons
    # https://docs.junction.com/api-reference/lab-testing/psc-scheduling/appointment-psc-cancellation-reasons
    # @return [Array<Hash>] each with id, name, is_refundable
    def self.cancellation_reasons
      Client.get("#{ENDPOINT}/psc/appointment/cancellation-reasons")
    end
  end
end
