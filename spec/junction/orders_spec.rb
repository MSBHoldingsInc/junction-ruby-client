# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Junction::Orders do
  let(:base) { 'https://api.sandbox.us.junction.com' }
  let(:json) { { 'Content-Type' => 'application/json' } }
  let(:pdf)  { { 'Content-Type' => 'application/pdf' } }

  describe '.create' do
    it 'POSTs the body and returns the parsed response' do
      stub_request(:post, "#{base}/v3/order")
        .with(body: { user_id: 'uuid-1' }.to_json)
        .to_return(status: 200, body: { id: 'order-1' }.to_json, headers: json)

      expect(described_class.create(user_id: 'uuid-1')).to eq('id' => 'order-1')
    end
  end

  describe '.find' do
    # Trimmed from a real GET /v3/order/{id} payload — keeps the nested shapes
    # (lab_test, events[], last_event) so we verify they round-trip intact.
    let(:order) do
      {
        id: 'order-1',
        user_id: 'user-1',
        status: 'completed',
        lab_test: { slug: 'general_wellness_female_002', method: 'testkit' },
        events: [
          { id: 429_336, status: 'received.testkit.ordered' },
          { id: 429_546, status: 'completed.testkit.completed' }
        ],
        last_event: { id: 429_546, status: 'completed.testkit.completed' }
      }
    end

    it 'GETs the order by id and returns the parsed response' do
      stub_request(:get, "#{base}/v3/order/order-1")
        .to_return(status: 200, body: order.to_json, headers: json)

      result = described_class.find('order-1')

      expect(result['status']).to eq('completed')
      expect(result.dig('lab_test', 'slug')).to eq('general_wellness_female_002')
      expect(result['events'].last['status']).to eq('completed.testkit.completed')
    end
  end

  describe '.requisition_pdf' do
    it 'requests the requisition PDF with an application/pdf Accept header and returns the raw bytes' do
      stub_request(:get, "#{base}/v3/order/order-1/requisition/pdf")
        .with(headers: { 'Accept' => 'application/pdf' })
        .to_return(status: 200, body: '%PDF-1.4 requisition', headers: pdf)

      expect(described_class.requisition_pdf('order-1')).to eq('%PDF-1.4 requisition')
    end
  end
end
