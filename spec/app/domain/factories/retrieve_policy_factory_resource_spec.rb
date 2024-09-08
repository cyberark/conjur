# frozen_string_literal: true

require 'spec_helper'

# Helper method for building a mocked policy with annotations
def mocked_policy(annotations = {})
  double(::Role).tap do |policy|
    mocked_annotations = [].tap do |array|
      annotations.each do |key, value|
        array << double(::Annotation).tap do |annotation|
          allow(annotation).to receive(:name).and_return(key.to_s)
          allow(annotation).to receive(:value).and_return(value.to_s)
        end
      end
    end

    allow(policy).to receive(:annotations).and_return(mocked_annotations)
  end
end

RSpec.describe(Factories::RetrievePolicyFactoryResource) do
  let(:resource_repository) { double(::Resource) }
  let(:factory) do
    # rubocop:disable Layout/LineLength
    DB::Repository::DataObjects::PolicyFactory.new(
      name: 'database',
      classification: 'connections',
      version: 'v1',
      schema: JSON.parse('{"$schema":"http://json-schema.org/draft-06/schema#","title":"Database Connection Template","description":"All information for connecting to a database","type":"object","properties":{"id":{"description":"Resource Identifier","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this resource into","type":"string"},"variables":{"type":"object","properties":{"url":{"description":"Database URL","type":"string"},"port":{"description":"Database Port","type":"string"},"username":{"description":"Database Username","type":"string"},"password":{"description":"Database Password","type":"string"},"ssl-certificate":{"description":"Client SSL Certificate","type":"string"},"ssl-key":{"description":"Client SSL Key","type":"string"},"ssl-ca-certificate":{"description":"CA Root Certificate","type":"string"}},"required":["url","port","username","password"]}},"required":["branch","id","variables"]}')
    )
    # rubocop:enable Layout/LineLength
  end
  let(:policy_factory_repository) do
    instance_double(DB::Repository::PolicyFactoryRepository).tap do |repo|
      allow(repo).to receive(:find).with(kind: 'connections', id: 'database', account: 'default', version: 'v1').and_return(
        ::SuccessResponse.new(factory)
      )
      allow(repo).to receive(:find).with(kind: 'connections', id: 'api', account: 'default', version: 'v1').and_return(
        ::FailureResponse.new('error')
      )
      allow(repo).to receive(:find).with(kind: 'core', id: 'policy', account: 'default', version: 'v1').and_return(
        ::SuccessResponse.new(
          # rubocop:disable Layout/LineLength
          DB::Repository::DataObjects::PolicyFactory.new(
            name: 'policy',
            classification: 'core',
            version: 'v1',
            schema: JSON.parse('{"$schema":"http://json-schema.org/draft-06/schema#","title":"Policy Template","description":"Creates a Conjur Policy","type":"object","properties":{"id":{"description":"Policy ID","type":"string"},"annotations":{"description":"Additional annotations","type":"object"},"branch":{"description":"Policy branch to load this policy into","type":"string"},"owner_role":{"description":"The Conjur Role that will own this policy","type":"string"},"owner_type":{"description":"The resource type of the owner of this policy","type":"string"}},"required":["branch","id"]}')
          )
          # rubocop:enable Layout/LineLength
        )
      )
    end
  end
  let(:secret_values) { { 'foo-bar/url' => 'http://my-test.mycompany.com' } }
  let(:secrets) { ::SuccessResponse.new(secret_values) }
  let(:secrets_repository) do
    instance_double(DB::Repository::SecretsRepository).tap do |repo|
      allow(repo).to receive(:find_all).and_return(secrets)
    end
  end
  subject do
    Factories::RetrievePolicyFactoryResource.new(
      resource_repository: resource_repository,
      policy_factory_repository: policy_factory_repository,
      secrets_repository: secrets_repository
    )
  end

  # What system level errors do we need to capture?

  describe '.call' do
    context 'when the target policy exists' do
      let(:policy) { mocked_policy({ factory: 'connections/v1/database' }) }
      before do
        expect(resource_repository).to receive(:[]).with("default:policy:foo-bar").and_return(policy)
      end
      context 'when the role has access to the target secrets' do
        context 'when policy has a factory annotation' do
          context 'when a policy has extra annotations' do
            it 'returns a success response' do
              response = subject.call(account: 'default', policy_identifier: 'foo-bar', current_user: 'foo-bar')
              expect(response.success?).to eq(true)
              expect(response.result).to eq(
                {
                  annotations: {},
                  id: 'foo-bar',
                  details: { classification: 'connections', identifier: 'database', version: 'v1' },
                  variables: {
                    'url' => { description: 'Database URL',  value: 'http://my-test.mycompany.com' },
                    'username' => { description: 'Database Username',  value: nil },
                    'password' => { description: 'Database Password', value: nil },
                    'port' => { description: 'Database Port',  value: nil },
                    'ssl-ca-certificate' => { description: 'CA Root Certificate',  value: nil },
                    'ssl-certificate' => { description: 'Client SSL Certificate',  value: nil },
                    'ssl-key' => { description: 'Client SSL Key',  value: nil }
                  }
                }
              )
            end
          end
          context 'when a policy only has the factory annotation' do
            it 'returns a success response' do
              response = subject.call(account: 'default', policy_identifier: 'foo-bar', current_user: 'foo-bar')
              expect(response.success?).to eq(true)
              expect(response.result).to eq(
                {
                  annotations: {},
                  id: 'foo-bar',
                  details: { classification: 'connections', identifier: 'database', version: 'v1' },
                  variables: {
                    'url' => { description: 'Database URL',  value: 'http://my-test.mycompany.com' },
                    'username' => { description: 'Database Username',  value: nil },
                    'password' => { description: 'Database Password', value: nil },
                    'port' => { description: 'Database Port',  value: nil },
                    'ssl-ca-certificate' => { description: 'CA Root Certificate',  value: nil },
                    'ssl-certificate' => { description: 'Client SSL Certificate',  value: nil },
                    'ssl-key' => { description: 'Client SSL Key',  value: nil }
                  }
                }
              )
            end
          end
        end
        context 'when the policy does not have a factory annotation' do
          let(:policy) { mocked_policy({ foo: 'bar' }) }
          it 'is unsuccess' do
            response = subject.call(account: 'default', policy_identifier: 'foo-bar', current_user: 'foo-bar')
            expect(response.success?).to eq(false)
            expect(response.message).to eq("Policy 'foo-bar' does not have a factory annotation.")
            expect(response.status).to eq(:not_found)
            expect(response.exception).to be_a(Errors::Factories::MissingFactoryAnnotation)
            expect(response.exception.message).to eq("CONJ00159E No factory annotation found for policy: 'foo-bar'")
          end
        end
      end
      context 'when the role does not have access to the target secrets' do
        let(:secrets) { ::FailureResponse.new('No variable secrets were found', status: :not_found, exception: StandardError.new('No variable secrets were found')) }
        it 'returns a failure response' do
          response = subject.call(account: 'default', policy_identifier: 'foo-bar', current_user: 'foo-bar')
          expect(response.success?).to eq(false)
          expect(response.message).to eq('No variable secrets were found')
          expect(response.status).to eq(:not_found)
        end
      end
      context 'when the policy factory does not have any variables' do
        let(:policy) { mocked_policy({ factory: 'core/v1/policy' }) }
        it 'returns a failure response' do
          response = subject.call(account: 'default', policy_identifier: 'foo-bar', current_user: 'foo-bar')
          expect(response.success?).to eq(false)
          expect(response.message).to eq("This factory created resource: 'default:policy:foo-bar' does not include any variables.")
          expect(response.status).to eq(:not_found)
          expect(response.exception).to be_a(Errors::Factories::NoVariablesFound)
          expect(response.exception.message).to eq("CONJ00161E No variables found for Factory created resource: 'default:policy:foo-bar'")
        end
      end
    end
    context 'when the target policy does not exist' do
      before do
        expect(resource_repository).to receive(:[]).with("default:policy:foo-bar").and_return(nil)
      end
      it 'returns a failure response' do
        response = subject.call(account: 'default', policy_identifier: 'foo-bar', current_user: 'foo-bar')
        expect(response.success?).to eq(false)
        expect(response.message).to eq("Policy 'foo-bar' was not found in account 'default'. Only policies with variables created from Factories can be retrieved using the Factory endpoint.")
        expect(response.status).to eq(:not_found)
        expect(response.exception).to be_a(Errors::Factories::FactoryGeneratedPolicyNotFound)
        expect(response.exception.message).to eq("CONJ00158E No policy found for Factory generated resource: 'foo-bar'")
      end
    end
    context 'when a policy factory was not found in annotations' do
      let(:policy) { mocked_policy({ factory: 'connections/v1/api' }) }
      before do
        expect(resource_repository).to receive(:[]).with("default:policy:foo-bar").and_return(policy)
      end
      it 'returns a failure response' do
        response = subject.call(account: 'default', policy_identifier: 'foo-bar', current_user: 'foo-bar')
        expect(response.success?).to eq(false)
        expect(response.message).to eq("A Policy Factory was not found for: 'connections/v1/api' in account 'default'.")
        expect(response.status).to eq(:not_found)
        expect(response.exception).to be_a(Errors::Factories::FactoryNotFound)
        expect(response.exception.message).to eq("CONJ00157E No Factory found for 'connections/v1/api'")
      end
    end
  end
end
