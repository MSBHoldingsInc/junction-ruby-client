# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Junction::Configuration do
  describe 'timeout defaults' do
    subject(:config) { described_class.new }

    it 'defaults open_timeout to 3 seconds' do
      expect(config.open_timeout).to eq(3)
    end

    it 'defaults read_timeout to 10 seconds' do
      expect(config.read_timeout).to eq(10)
    end

    it 'defaults write_timeout to 10 seconds' do
      expect(config.write_timeout).to eq(10)
    end
  end

  describe 'overriding timeouts in the configure block' do
    it 'keeps the values assigned' do
      Junction.configure do |c|
        c.open_timeout  = 1
        c.read_timeout  = 30
        c.write_timeout = 20
      end

      expect(Junction.configuration).to have_attributes(open_timeout: 1, read_timeout: 30, write_timeout: 20)
    end

    it 'allows nil to fall back to the underlying Net::HTTP default' do
      Junction.configure { |c| c.read_timeout = nil }

      expect(Junction.configuration.read_timeout).to be_nil
    end
  end

  describe '.reset_configuration!' do
    it 'restores the timeout defaults' do
      Junction.configure { |c| c.open_timeout = 99 }
      Junction.reset_configuration!

      expect(Junction.configuration.open_timeout).to eq(3)
    end
  end
end
