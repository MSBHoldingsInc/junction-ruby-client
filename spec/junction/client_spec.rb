# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Junction::Client do
  let(:base) { 'https://api.sandbox.us.junction.com' }
  let(:json) { { 'Content-Type' => 'application/json' } }

  describe '.get' do
    it 'sends the x-vital-api-key header and returns the parsed body' do
      stub = stub_request(:get, "#{base}/v2/ping")
             .with(headers: { 'x-vital-api-key' => 'test-key', 'Accept' => 'application/json' })
             .to_return(status: 200, body: { ok: true }.to_json, headers: json)

      expect(described_class.get('/v2/ping')).to eq('ok' => true)
      expect(stub).to have_been_requested
    end

    it 'appends query params' do
      stub = stub_request(:get, "#{base}/v2/ping").with(query: { a: '1' })
             .to_return(status: 200, body: '{}', headers: json)

      described_class.get('/v2/ping', a: '1')
      expect(stub).to have_been_requested
    end
  end

  describe '.post' do
    it 'serializes the body to JSON' do
      stub = stub_request(:post, "#{base}/v2/user")
             .with(body: { client_user_id: 'abc' }.to_json, headers: { 'x-vital-api-key' => 'test-key' })
             .to_return(status: 200, body: '{}', headers: json)

      described_class.post('/v2/user', client_user_id: 'abc')
      expect(stub).to have_been_requested
    end
  end

  describe '.patch' do
    it 'serializes the body to JSON' do
      stub = stub_request(:patch, "#{base}/v2/user/uuid/info")
             .with(body: { first_name: 'Jo' }.to_json)
             .to_return(status: 200, body: '{}', headers: json)

      described_class.patch('/v2/user/uuid/info', first_name: 'Jo')
      expect(stub).to have_been_requested
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

  describe 'configuration' do
    it 'targets the configured base_uri at request time' do
      Junction.configure { |c| c.base_uri = 'https://api.us.junction.com' }
      stub = stub_request(:get, 'https://api.us.junction.com/v2/ping')
             .to_return(status: 200, body: '{}', headers: json)

      described_class.get('/v2/ping')
      expect(stub).to have_been_requested
    end
  end
end
