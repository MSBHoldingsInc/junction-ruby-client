# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Junction::LabResults do
  let(:base) { 'https://api.sandbox.us.junction.com' }
  let(:json) { { 'Content-Type' => 'application/json' } }
  let(:pdf)  { { 'Content-Type' => 'application/pdf' } }

  describe '.find' do
    # Trimmed from a real GET /v3/order/{id}/result payload. Includes both a
    # `numeric` and a `range` marker so the spec documents the `value` (number)
    # vs `result` (display string) distinction and the range sentinel value.
    let(:results_body) do
      {
        metadata: { patient: 'Jane Doe', status: 'final', interpretation: 'abnormal' },
        results: [
          { name: 'HDL Cholesterol', slug: 'hdl', value: 50.0, result: '50', type: 'numeric', interpretation: 'normal' },
          { name: 'Estradiol (Sensitive)', slug: 'estradiol', value: -1.0, result: '<15', type: 'range',
            is_below_min_range: true, interpretation: 'abnormal' }
        ],
        missing_results: nil,
        order_transaction: { id: 'txn-1', status: 'completed' }
      }
    end

    it 'GETs the result endpoint and returns the parsed response' do
      stub_request(:get, "#{base}/v3/order/order-1/result")
        .to_return(status: 200, body: results_body.to_json, headers: json)

      result = described_class.find('order-1')

      expect(result.dig('metadata', 'status')).to eq('final')

      numeric = result['results'].first
      expect(numeric['value']).to eq(50.0)   # numeric reading
      expect(numeric['result']).to eq('50')  # lab's display string

      range = result['results'].last
      expect(range['type']).to eq('range')
      expect(range['value']).to eq(-1.0)     # sentinel for range-type results
      expect(range['is_below_min_range']).to be(true)

      expect(result.dig('order_transaction', 'status')).to eq('completed')
    end
  end

  describe '.pdf' do
    it 'requests the result PDF with an application/pdf Accept header and returns the raw bytes' do
      stub_request(:get, "#{base}/v3/order/order-1/result/pdf")
        .with(headers: { 'Accept' => 'application/pdf' })
        .to_return(status: 200, body: '%PDF-1.4 results', headers: pdf)

      expect(described_class.pdf('order-1')).to eq('%PDF-1.4 results')
    end
  end
end
