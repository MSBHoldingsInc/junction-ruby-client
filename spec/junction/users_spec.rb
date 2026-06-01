# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Junction::Users do
  let(:base) { 'https://api.sandbox.us.junction.com' }
  let(:json) { { 'Content-Type' => 'application/json' } }

  describe '.create' do
    it 'POSTs the client_user_id and returns the parsed body' do
      stub = stub_request(:post, "#{base}/v2/user")
             .with(body: { client_user_id: 'abc' }.to_json)
             .to_return(status: 200, body: { user_id: 'uuid-1' }.to_json, headers: json)

      expect(described_class.create('abc')).to eq('user_id' => 'uuid-1')
      expect(stub).to have_been_requested
    end
  end

  describe '.find' do
    it 'GETs the user by Junction user_id' do
      stub = stub_request(:get, "#{base}/v2/user/uuid-1").to_return(status: 200, body: '{}', headers: json)

      described_class.find('uuid-1')
      expect(stub).to have_been_requested
    end
  end

  describe '.find_by_client_user_id' do
    it 'GETs the resolve endpoint' do
      stub = stub_request(:get, "#{base}/v2/user/resolve/abc").to_return(status: 200, body: '{}', headers: json)

      described_class.find_by_client_user_id('abc')
      expect(stub).to have_been_requested
    end
  end

  describe '.update_user_demographics' do
    it 'PATCHes the info endpoint with the given body' do
      stub = stub_request(:patch, "#{base}/v2/user/uuid-1/info")
             .with(body: { first_name: 'Jo' }.to_json)
             .to_return(status: 200, body: '{}', headers: json)

      described_class.update_user_demographics('uuid-1', first_name: 'Jo')
      expect(stub).to have_been_requested
    end
  end
end
