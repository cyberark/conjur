# frozen_string_literal: true

require 'spec_helper'

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

RSpec.describe(Factories::ResourceCircuitBreaker) do
  let(:resource_repository) do
    spy(::Resource).tap do |double|
      allow(double).to receive(:[]).with(resource_id).and_return(resource_response)
    end
  end
  let(:role_repository) do
    spy(::Role).tap do |double|
      allow(double).to receive(:[]).with(role_id).and_return(role_response)
    end
  end
  let(:policy_loader) do
    spy(CommandHandler::Policy).tap do |double|
      allow(double).to receive(:call).and_return(policy_response)
    end
  end
  let(:policy_response) { SuccessResponse.new('Success') }
  subject do
    described_class.new(
      resource_repository: resource_repository,
      role_repository: role_repository,
      policy_loader: policy_loader
    )
  end

  let(:resource_id) { 'rspec:policy:foo-bar' }
  let(:resource_response) { mocked_policy(factory: 'connections/v1/database') }
  let(:role_id) { 'rspec:group:foo-bar/circuit-breaker' }
  let(:role_response) { "success" }

  describe '#call' do
    context 'when role is attempting to either "enable" or "disable" a circuit breaker' do
      context 'when the action includes capital letters' do
        %w[enAblE disABLE].each do |action|
          it 'returns a failure response' do
            result = subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: action, request_ip: '127.0.0.1', role: 'foo')
            expect(result).to be_a(SuccessResponse)
          end
        end
      end
      context 'when a circuit breaker group exists in the target policy' do
        context 'when the policy exists' do
          context 'when the factory can be identified from the target policy' do
            context 'when the target policy is the root policy' do
              context 'when the factory kind is a connection' do
                context 'when the target action is "disable" the breaker' do
                  it 'calls the policy loader with the correct parameters' do
                    expect(policy_loader).to receive(:call).with(
                      target_policy_id: "rspec:policy:root",
                      request_ip: '127.0.0.1',
                      policy: "- !revoke\n  member: !group foo-bar/consumers\n  role: !group foo-bar/circuit-breaker\n",
                      loader: Loader::ModifyPolicy,
                      request_type: 'PATCH',
                      role: 'foo'
                    )
                    subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: 'disable', request_ip: '127.0.0.1', role: 'foo')
                  end
                end
                context 'when the target action is "enable" the breaker' do
                  it 'calls the policy loader with the correct parameters' do
                    expect(policy_loader).to receive(:call).with(
                      target_policy_id: "rspec:policy:root",
                      request_ip: '127.0.0.1',
                      policy: "- !grant\n  member: !group foo-bar/consumers\n  role: !group foo-bar/circuit-breaker\n",
                      loader: Loader::ModifyPolicy,
                      request_type: 'PATCH',
                      role: 'foo'
                    )
                    subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: 'enable', request_ip: '127.0.0.1', role: 'foo')
                  end
                end
              end
              context 'when the factory kind is an authenticator' do
                let(:resource_response) { mocked_policy(factory: 'authenticators/v1/authn-iam') }
                context 'when the target action is "disable" the breaker' do
                  it 'calls the policy loader with the correct parameters' do
                    expect(policy_loader).to receive(:call).with(
                      target_policy_id: "rspec:policy:root",
                      request_ip: '127.0.0.1',
                      policy: "- !revoke\n  member: !group foo-bar/authenticatable\n  role: !group foo-bar/circuit-breaker\n",
                      loader: Loader::ModifyPolicy,
                      request_type: 'PATCH',
                      role: 'foo'
                    )
                    subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: 'disable', request_ip: '127.0.0.1', role: 'foo')
                  end
                end
                context 'when the target action is "enable" the breaker' do
                  it 'calls the policy loader with the correct parameters' do
                    expect(policy_loader).to receive(:call).with(
                      target_policy_id: "rspec:policy:root",
                      request_ip: '127.0.0.1',
                      policy: "- !grant\n  member: !group foo-bar/authenticatable\n  role: !group foo-bar/circuit-breaker\n",
                      loader: Loader::ModifyPolicy,
                      request_type: 'PATCH',
                      role: 'foo'
                    )
                    subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: 'enable', request_ip: '127.0.0.1', role: 'foo')
                  end
                end
              end
            end
            context 'when the target policy is not the root policy' do
              let(:role_id) { 'rspec:group:baz/foo-bar/circuit-breaker' }
              let(:role_response) { "success" }
              let(:resource_id) { 'rspec:policy:baz/foo-bar' }
              context 'when the target action is "disable" the breaker' do
                it 'calls the policy loader with the correct parameters' do
                  expect(policy_loader).to receive(:call).with(
                    target_policy_id: "rspec:policy:baz",
                    request_ip: '127.0.0.1',
                    policy: "- !revoke\n  member: !group foo-bar/consumers\n  role: !group foo-bar/circuit-breaker\n",
                    loader: Loader::ModifyPolicy,
                    request_type: 'PATCH',
                    role: 'foo'
                  )
                  subject.call(account: 'rspec', policy_identifier: 'baz/foo-bar', action: 'disable', request_ip: '127.0.0.1', role: 'foo')
                end
              end
              context 'when the target action is "enable" the breaker' do
                it 'calls the policy loader with the correct parameters' do
                  expect(policy_loader).to receive(:call).with(
                    target_policy_id: "rspec:policy:baz",
                    request_ip: '127.0.0.1',
                    policy: "- !grant\n  member: !group foo-bar/consumers\n  role: !group foo-bar/circuit-breaker\n",
                    loader: Loader::ModifyPolicy,
                    request_type: 'PATCH',
                    role: 'foo'
                  )
                  subject.call(account: 'rspec', policy_identifier: 'baz/foo-bar', action: 'enable', request_ip: '127.0.0.1', role: 'foo')
                end
              end
            end
          end
          context 'when the factory cannot be identified from the target policy' do
            let(:resource_response) { mocked_policy }
            it 'returns a failure response' do
              result = subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: 'enable', request_ip: '127.0.0.1', role: 'foo')
              expect(result).to be_a(FailureResponse)
              expect(result.message).to eq("Policy 'foo-bar' does not have a factory annotation.")
              expect(result.status).to eq(:not_found)
              expect(result.exception).to be_a(Errors::Factories::MissingFactoryAnnotation)
              expect(result.exception.message).to eq("CONJ00159E No factory annotation found for policy: 'foo-bar'")
            end
          end
        end
        context 'when the policy does not exist' do
          let(:resource_response) { nil }
          it 'returns a failure response' do
            result = subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: 'enable', request_ip: '127.0.0.1', role: 'foo')
            expect(result).to be_a(FailureResponse)
            expect(result.message).to eq("Policy 'foo-bar' was not found in account 'rspec'. Only policies with variables created from Factories can be retrieved using the Factory endpoint.")
            expect(result.status).to eq(:not_found)
            expect(result.exception).to be_a(Errors::Factories::FactoryGeneratedPolicyNotFound)
            expect(result.exception.message).to eq("CONJ00158E No policy found for Factory generated resource: 'foo-bar'")
          end
        end
      end
      context 'when a circuit breaker group does not exist in the target policy' do
        let(:role_response) { nil }
        it 'returns a failure response' do
          result = subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: 'enable', request_ip: '127.0.0.1', role: 'foo')
          expect(result).to be_a(FailureResponse)
          expect(result.message).to eq("Factory generated policy 'foo-bar' does not include a circuit-breaker group.")
          expect(result.status).to eq(:not_implemented)
        end
      end
    end
    context 'when the role is attempting to perform an action other than "enable" or "disable"' do
      ['foo', nil].each do |action|
        it 'returns a failure response' do
          result = subject.call(account: 'rspec', policy_identifier: 'foo-bar', action: action, request_ip: '127.0.0.1', role: 'foo')
          expect(result).to be_a(FailureResponse)
          expect(result.message).to eq("Only 'enable' and 'disable' actions are supported.")
          expect(result.status).to eq(:bad_request)
        end
      end
    end
  end
end
