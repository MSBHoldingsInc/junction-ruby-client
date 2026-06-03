# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Junction::PatientServiceCenters do
  let(:base) { 'https://api.sandbox.us.junction.com' }
  let(:json) { { 'Content-Type' => 'application/json' } }

  describe '.coverage' do
    # Trimmed from a real GET /v3/order/area/info payload — keyed by lab slug,
    # each value carrying a lab_id (the shape you'd map over to pull lab ids).
    let(:coverage_body) do
      {
        quest: { patient_service_centers: { within_radius: 27 }, lab_id: 4 },
        labcorp: { patient_service_centers: { within_radius: 66 }, lab_id: 6 }
      }
    end

    it 'GETs area/info with the zip and default radius, and returns the parsed response' do
      stub_request(:get, "#{base}/v3/order/area/info")
        .with(query: { zip_code: '85004', radius: '25' })
        .to_return(status: 200, body: coverage_body.to_json, headers: json)

      result = described_class.coverage('85004')

      expect(result.transform_values { |lab| lab['lab_id'] }).to eq('quest' => 4, 'labcorp' => 6)
    end

    it 'passes an explicit radius through' do
      stub_request(:get, "#{base}/v3/order/area/info")
        .with(query: { zip_code: '85004', radius: '100' })
        .to_return(status: 200, body: '{}', headers: json)

      expect(described_class.coverage('85004', radius: 100)).to eq({})
    end
  end

  describe '.near' do
    it 'GETs psc/info with the zip, lab_id, and default radius' do
      stub_request(:get, "#{base}/v3/order/psc/info")
        .with(query: { zip_code: '85004', lab_id: '4', radius: '25' })
        .to_return(status: 200, body: { centers: [] }.to_json, headers: json)

      expect(described_class.near('85004', lab_id: 4)).to eq('centers' => [])
    end
  end

  describe '.for_order' do
    it 'GETs the order-scoped psc/info with the default radius' do
      stub_request(:get, "#{base}/v3/order/order-1/psc/info")
        .with(query: { radius: '25' })
        .to_return(status: 200, body: { centers: [] }.to_json, headers: json)

      expect(described_class.for_order('order-1')).to eq('centers' => [])
    end
  end
end
