# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Junction::Appointments do
  let(:base) { 'https://api.sandbox.us.junction.com' }
  let(:json) { { 'Content-Type' => 'application/json' } }

  describe '.availability' do
    # Trimmed from a real POST /v3/order/psc/appointment/availability payload —
    # keeps the per-location / per-day nesting so we verify it round-trips.
    let(:availability_body) do
      {
        slots: [
          {
            location: { code: 'ABC123', name: 'Quest - Phoenix', iana_timezone: 'America/Phoenix' },
            date: '2026-06-15',
            slots: [
              { booking_key: 'bk-1', start: '2026-06-15T15:00:00Z', end: '2026-06-15T15:15:00Z', price: 0 }
            ]
          }
        ],
        timezone: nil
      }
    end

    it 'POSTs the params in the query string and returns the parsed response' do
      stub_request(:post, "#{base}/v3/order/psc/appointment/availability")
        .with(query: { lab: 'quest', zip_code: '85004', radius: '25' })
        .to_return(status: 200, body: availability_body.to_json, headers: json)

      result = described_class.availability(lab: 'quest', zip_code: '85004', radius: 25)

      expect(result['slots'].first.dig('location', 'iana_timezone')).to eq('America/Phoenix')
      expect(result['slots'].first['slots'].first['booking_key']).to eq('bk-1')
      expect(result['timezone']).to be_nil
    end

    it 'defaults radius to 25 when omitted' do
      stub_request(:post, "#{base}/v3/order/psc/appointment/availability")
        .with(query: { lab: 'quest', zip_code: '85004', radius: '25' })
        .to_return(status: 200, body: '{}', headers: json)

      expect(described_class.availability(lab: 'quest', zip_code: '85004')).to eq({})
    end

    it 'coerces radius to a string and passes optional filters through' do
      stub_request(:post, "#{base}/v3/order/psc/appointment/availability")
        .with(query: { lab: 'quest', zip_code: '85004', radius: '50', start_date: '2026-06-15' })
        .to_return(status: 200, body: '{}', headers: json)

      expect(described_class.availability(lab: 'quest', zip_code: '85004', radius: 50, start_date: '2026-06-15'))
        .to eq({})
    end
  end

  describe '.book' do
    it 'POSTs the booking_key and returns the appointment' do
      stub_request(:post, "#{base}/v3/order/order-1/psc/appointment/book")
        .with(body: { booking_key: 'bk-1' }.to_json)
        .to_return(status: 200, body: { id: 'appt-1', status: 'confirmed' }.to_json, headers: json)

      result = described_class.book('order-1', booking_key: 'bk-1')

      expect(result['id']).to eq('appt-1')
      expect(result['status']).to eq('confirmed')
    end

    it 'includes appointment_notes when given' do
      stub_request(:post, "#{base}/v3/order/order-1/psc/appointment/book")
        .with(body: { booking_key: 'bk-1', appointment_notes: 'wheelchair access' }.to_json)
        .to_return(status: 200, body: { id: 'appt-1' }.to_json, headers: json)

      expect(described_class.book('order-1', booking_key: 'bk-1', appointment_notes: 'wheelchair access'))
        .to eq('id' => 'appt-1')
    end
  end

  describe '.reschedule' do
    it 'PATCHes the new booking_key and returns the updated appointment' do
      stub_request(:patch, "#{base}/v3/order/order-1/psc/appointment/reschedule")
        .with(body: { booking_key: 'bk-2' }.to_json)
        .to_return(status: 200, body: { id: 'appt-1', start_at: '2026-06-16T15:00:00Z' }.to_json, headers: json)

      expect(described_class.reschedule('order-1', booking_key: 'bk-2'))
        .to eq('id' => 'appt-1', 'start_at' => '2026-06-16T15:00:00Z')
    end
  end

  describe '.cancel' do
    it 'PATCHes the cancellation_reason_id and returns the cancelled appointment' do
      stub_request(:patch, "#{base}/v3/order/order-1/psc/appointment/cancel")
        .with(body: { cancellation_reason_id: 'reason-1' }.to_json)
        .to_return(status: 200, body: { id: 'appt-1', status: 'cancelled' }.to_json, headers: json)

      expect(described_class.cancel('order-1', cancellation_reason_id: 'reason-1'))
        .to eq('id' => 'appt-1', 'status' => 'cancelled')
    end

    it 'includes the note when given' do
      stub_request(:patch, "#{base}/v3/order/order-1/psc/appointment/cancel")
        .with(body: { cancellation_reason_id: 'reason-1', note: 'patient moved' }.to_json)
        .to_return(status: 200, body: { id: 'appt-1', status: 'cancelled' }.to_json, headers: json)

      expect(described_class.cancel('order-1', cancellation_reason_id: 'reason-1', note: 'patient moved'))
        .to eq('id' => 'appt-1', 'status' => 'cancelled')
    end
  end

  describe '.find' do
    it 'GETs the order-scoped appointment and returns the parsed response' do
      stub_request(:get, "#{base}/v3/order/order-1/psc/appointment")
        .to_return(status: 200, body: { id: 'appt-1', status: 'confirmed' }.to_json, headers: json)

      result = described_class.find('order-1')

      expect(result['id']).to eq('appt-1')
      expect(result['status']).to eq('confirmed')
    end
  end

  describe '.cancellation_reasons' do
    it 'GETs the cancellation reasons list' do
      reasons = [{ id: 'reason-1', name: 'Other', is_refundable: true }]

      stub_request(:get, "#{base}/v3/order/psc/appointment/cancellation-reasons")
        .to_return(status: 200, body: reasons.to_json, headers: json)

      result = described_class.cancellation_reasons

      expect(result.first['id']).to eq('reason-1')
      expect(result.first['is_refundable']).to be(true)
    end
  end
end
