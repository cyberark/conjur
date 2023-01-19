require 'spec_helper'
require 'conjur/fetch_required_secrets'
require 'util/stubs/deep_double'

RSpec.describe 'Conjur::FetchRequiredSecrets' do

  def fetch_secrets(repo)
    Conjur::FetchRequiredSecrets
      .new(resource_class: repo)
      .(resource_ids: ['resource1', 'resource2'])
  end

  DeepDouble = Util::Stubs::DeepDouble

  context 'when the secrets exist' do

    let(:repo_with_secrets) do
      DeepDouble.new('ResourceRepo',
        '[]': {
          'resource1' => {secret: {value: 'secret1'}},
          'resource2' => {secret: {value: 'secret2'}}
        }
      )
    end

    it 'returns a hash of the secret values indexed by resource id' do
      expect(fetch_secrets(repo_with_secrets)).to eq(
        { 'resource1' => 'secret1', 'resource2' => 'secret2' }
      )
    end
  end

  context 'when resources are missing' do
    let(:repo_missing_resource) do
      DeepDouble.new('ResourceRepo',
        '[]': {
          'resource1' => nil,
          'resource2' => {secret: {value: 'secret2'}}
        }
      )
    end

    it 'raises RequiredResourceMissing' do
      expect{ fetch_secrets(repo_missing_resource) }.to raise_error(
        Errors::Conjur::RequiredResourceMissing
      )
    end
  end

  context 'when secrets are missing' do
    let(:repo_missing_secret) do
      DeepDouble.new('ResourceRepo',
        '[]': {
          'resource1' => {secret: {value: 'secret1'}},
          'resource2' => {secret: nil}
        }
      )
    end

    it 'raises RequiredSecretMissing' do
      expect{ fetch_secrets(repo_missing_secret) }.to raise_error(
        Errors::Conjur::RequiredSecretMissing
      )
    end
  end
end
