# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::Validations::AuthenticatorConfiguration) do
  let(:validations) { described_class.new(utils: ::Util::ContractUtils) }
  # let(:default_args) { { account: 'foo', service_id: 'bar' } }
  # let(:public_keys) { '{"type":"jwks","value":{"keys":[{}]}}' }

  let(:default_data) do
    {
      account: 'rspec',
      service_id: 'oidc-1',
      provider_uri: 'http://test.com',
      client_id: 'client-id',
      client_secret: 'client-secret',
      claim_mapping: 'email'
    }
  end
  let(:data) { default_data }

  context 'when all required data is present' do
    it 'is valid' do
      response = validations.call(**data)

      expect(response.success?).to be(true)
      expect(response.to_h).to eq(data)
    end
  end
  context 'when provider_uri is an empty string' do
    let(:data) do
      {
        account: 'rspec',
        service_id: 'oidc-1',
        provider_uri: '',
        client_id: 'client-id',
        client_secret: 'client-secret',
        claim_mapping: 'email'
      }
    end
    it 'is not valid' do
      response = validations.call(**data)
      expect(response.success?).to be(false)
      expect(response.errors.count).to eq(1)
      expect(response.errors.first.path).to eq([:provider_uri])
      expect(response.errors.first.text).to eq('must be filled')
    end
  end

  # context 'when more than one of the following are set: jwks_uri, public_keys, and provider_uri' do
  #   context 'when jwks_uri and public_keys are set' do
  #     # TODO: this error message doesn't make sense...
  #     let(:params) { default_args.merge(jwks_uri: 'foo', public_keys: public_keys) }
  #     it 'is unsuccessful' do
  #       expect(subject.success?).to be(false)
  #       expect(subject.errors.first.text).to eq(
  #         'CONJ00154E Invalid signing key settings: jwks-uri and provider-uri cannot be defined simultaneously'
  #       )
  #     end
  #   end
end
