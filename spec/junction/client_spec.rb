# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Junction::Client do
  let(:base) { 'https://api.sandbox.us.junction.com' }
  let(:json) { { 'Content-Type' => 'application/json' } }

  describe '.get' do
    it 'sends the x-vital-api-key header and returns the parsed body' do
      stub_request(:get, "#{base}/v2/ping")
        .with(headers: { 'x-vital-api-key' => 'test-key', 'Accept' => 'application/json' })
        .to_return(status: 200, body: { ok: true }.to_json, headers: json)

      expect(described_class.get('/v2/ping')).to eq('ok' => true)
    end

    it 'appends query params' do
      stub_request(:get, "#{base}/v2/ping").with(query: { a: '1' })
        .to_return(status: 200, body: { ok: true }.to_json, headers: json)

      expect(described_class.get('/v2/ping', a: '1')).to eq('ok' => true)
    end

    it 'merges custom headers over the defaults' do
      stub_request(:get, "#{base}/v2/ping")
        .with(headers: { 'x-vital-api-key' => 'test-key', 'Accept' => 'application/pdf' })
        .to_return(status: 200, body: '%PDF-1.4', headers: { 'Content-Type' => 'application/pdf' })

      expect(described_class.get('/v2/ping', {}, { 'Accept' => 'application/pdf' })).to eq('%PDF-1.4')
    end
  end

  describe '.post' do
    it 'serializes the body to JSON' do
      stub_request(:post, "#{base}/v2/user")
        .with(body: { client_user_id: 'abc' }.to_json, headers: { 'x-vital-api-key' => 'test-key' })
        .to_return(status: 200, body: { user_id: 'uuid-1' }.to_json, headers: json)

      expect(described_class.post('/v2/user', client_user_id: 'abc')).to eq('user_id' => 'uuid-1')
    end
  end

  describe '.patch' do
    it 'serializes the body to JSON' do
      stub_request(:patch, "#{base}/v2/user/uuid/info")
        .with(body: { first_name: 'Jo' }.to_json)
        .to_return(status: 200, body: { user_id: 'uuid' }.to_json, headers: json)

      expect(described_class.patch('/v2/user/uuid/info', first_name: 'Jo')).to eq('user_id' => 'uuid')
    end
  end

  describe 'error handling' do
    it 'raises RequestError on a non-2xx response, with the response attached' do
      stub_request(:get, "#{base}/v2/user/missing").to_return(status: 404, body: 'not found')

      expect { described_class.get('/v2/user/missing') }
        .to raise_error(Junction::Client::RequestError) { |e|
          expect(e.response.code).to eq(404)
          expect(e.message).to include('404')
        }
    end
  end
end
