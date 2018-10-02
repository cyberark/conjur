require 'conjur/fetch_required_secrets'
require 'util/mocks/unary_method_double'

RSpec.describe 'Conjur::FetchRequiredSecrets' do

  def secret(val)
    double('Secret').tap do |x|
      allow(x).to receive(:value).and_return(val)
    end
  end

  def resource(val)
    double('Resource').tap do |x|
      allow(x).to receive(:secret).and_return(val)
    end
  end

  def resource_repo(return_vals, errors = {})
    Util::Mocks::UnaryMethodDouble.new(
      method_name: :[],
      return_vals: return_vals,
      errors: errors
    )
  end

  def fetch_secrets(rsc_repo)
    Conjur::FetchRequiredSecrets.new(resource_repo: rsc_repo)
  end

  let(:secret1) { secret('secret1') }
  let(:secret2) { secret('secret2') }
  let(:resource1) { resource(secret1) }
  let(:resource2) { resource(secret2) }
  let(:required_resources) { ['resource1', 'resource2'] }

  context 'when the secrets exist' do

    let(:repo_with_secrets) do
      resource_repo({'resource1' => resource1, 'resource2' => resource2})
    end
    let(:fetch) { fetch_secrets(repo_with_secrets) }
    subject(:call_fetch) { fetch.(resource_ids: required_resources) }

    it 'returns a hash of the secret values indexed by resource id' do
      expect(fetch.(resource_ids: required_resources)).to eq(
        { 'resource1' => 'secret1', 'resource2' => 'secret2' }
      )
    end
  end

  context 'when resources are missing' do
    let(:repo_missing_resource) do
      resource_repo({'resource1' => nil, 'resource2' => resource2})
    end
    let(:fetch) { fetch_secrets(repo_missing_resource) }
    subject(:call_fetch) { fetch.(resource_ids: required_resources) }

    it 'raises RequiredResourceMissing' do
      expect{ call_fetch }.to raise_error(
        Conjur::RequiredResourceMissing
      )
    end
  end

  context 'when secrets are missing' do
    let(:resource_without_secret) { resource(nil) }
    let(:repo_missing_secret) do
      resource_repo({
        'resource1' => resource1,
        'resource2' => resource_without_secret
      })
    end
    let(:fetch) { fetch_secrets(repo_missing_secret) }
    subject(:call_fetch) { fetch.(resource_ids: required_resources) }

    it 'raises RequiredSecretMissing' do
      expect{ call_fetch }.to raise_error(
        Conjur::RequiredSecretMissing
      )
    end
  end
end
