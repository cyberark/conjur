# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnApiKey::V2::DataObjects::Authenticator) do
  let(:args) do
    { account: 'default' }
  end

  let(:authenticator) { described_class.new(**args) }

  describe '.type', type: 'unit' do
    it 'is overriden to the expected value' do
      expect(authenticator.type).to eq('authn')
    end
  end

  describe '.resource_id', type: 'unit' do
    it 'does not include the service_id' do
      expect(authenticator.resource_id).to eq('default:webservice:conjur/authn')
    end
  end
end
