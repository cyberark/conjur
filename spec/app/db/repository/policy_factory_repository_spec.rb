# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(DB::Repository::PolicyFactoryRepository) do
  # Ensure the variables below have not been set in previous tests
  before(:all) do
    ::Resource['rspec:variable:conjur/factories/core/v1/group']&.destroy
    ::Resource['rspec:variable:conjur/factories/core/v1/user']&.destroy
  end
  subject { DB::Repository::PolicyFactoryRepository.new }

  describe 'find_all' do
    context 'when no factories exist' do
      before(:each) do
        ::Role.create(role_id: 'rspec:group:conjur/policy-factory-users')
      end
      after(:each) do
        ::Role['rspec:group:conjur/policy-factory-users'].destroy
      end
      it 'returns an error' do
        response = subject.find_all(
          account: 'foo-bar',
          role: ::Role['rspec:group:conjur/policy-factory-users']
        )
        expect(response.success?).to eq(false)
        expect(response.status).to eq(:forbidden)
        expect(response.message).to eq('Role does not have permission to use Factories')
      end
    end

    context 'when factories exist' do
      let(:role_id) { 'rspec:group:conjur/policy-factory-users' }
      let(:owner_id) { role_id }
      let(:factory1) { 'rspec:variable:conjur/factories/core/v1/group' }
      let(:factory2) { 'rspec:variable:conjur/factories/core/v1/user' }

      before(:each) do
        ::Role.create(role_id: role_id)
      end
      after(:each) do
        ::Role[role_id].destroy
      end

      context 'when role does not have execute permission on any factories' do
        let(:owner_id) { 'rspec:group:admin' }
        before(:each) do
          ::Role.create(role_id: owner_id)
          ::Resource.create(resource_id: factory1, owner_id: owner_id)
          ::Secret.create(
            resource_id: factory1,
            value: Factories::Templates::Core::V1::Group.data
          )
          ::Resource.create(resource_id: factory2, owner_id: owner_id)
          ::Secret.create(
            resource_id: factory2,
            value: Factories::Templates::Core::V1::User.data
          )
        end
        after(:each) do
          ::Resource[factory1].destroy
          ::Resource[factory2].destroy
          ::Role[owner_id].destroy
        end
        it 'returns an error' do
          response = subject.find_all(
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(false)
          expect(response.status).to eq(:forbidden)
          expect(response.message).to eq('Role does not have permission to use Factories')
        end
      end
      context 'when role has execute permission on some factories' do
        let(:owner_id) { 'rspec:group:admin' }
        before(:each) do
          ::Role.create(role_id: owner_id)
          ::Resource.create(resource_id: factory1, owner_id: role_id)
          ::Secret.create(
            resource_id: factory1,
            value: Factories::Templates::Core::V1::Group.data
          )
          ::Resource.create(resource_id: factory2, owner_id: owner_id)
          ::Secret.create(
            resource_id: factory2,
            value: Factories::Templates::Core::V1::User.data
          )
        end
        after(:each) do
          ::Resource[factory1].destroy
          ::Resource[factory2].destroy
          ::Role[owner_id].destroy
        end
        it 'returns permitted factories' do
          response = subject.find_all(
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(true)
          expect(response.result.count).to eq(1)
          expect(response.result.first.name).to eq('group')
          expect(response.result.first.description).to eq('Creates a Conjur Group')
        end
      end
      context 'when role has execute permission on all factories' do
        before(:each) do
          ::Resource.create(resource_id: factory1, owner_id: role_id)
          ::Secret.create(
            resource_id: factory1,
            value: Factories::Templates::Core::V1::Group.data
          )
          ::Resource.create(resource_id: factory2, owner_id: role_id)
          ::Secret.create(
            resource_id: factory2,
            value: Factories::Templates::Core::V1::User.data
          )
        end
        after(:each) do
          ::Resource[factory1].destroy
          ::Resource[factory2].destroy
        end
        it 'returns all factories' do
          response = subject.find_all(
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(true)
          expect(response.result.count).to eq(2)
          expect(response.result.map(&:name)).to include('group')
          expect(response.result.map(&:name)).to include('user')
        end
      end
      context 'when multiple versions of a factory exist' do
        let(:factory1) { 'rspec:variable:conjur/factories/core/v1/group' }
        let(:factory2) { 'rspec:variable:conjur/factories/core/v2/group' }
        before(:each) do
          ::Resource.create(resource_id: factory1, owner_id: role_id)
          ::Secret.create(
            resource_id: factory1,
            value: Factories::Templates::Core::V1::Group.data
          )
          ::Resource.create(resource_id: factory2, owner_id: role_id)
          ::Secret.create(
            resource_id: factory2,
            value: Factories::Templates::Core::V1::Group.data
          )
        end
        after(:each) do
          ::Resource[factory1].destroy
          ::Resource[factory2].destroy
        end
        it 'returns the latest version' do
          response = subject.find_all(
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(true)
          expect(response.result.count).to eq(1)
          expect(response.result.first.version).to eq('v2')
        end
        context 'when there are more than 10 factory versions' do
          let(:factory1) { 'rspec:variable:conjur/factories/core/v9/group' }
          let(:factory2) { 'rspec:variable:conjur/factories/core/v10/group' }
          it 'returns the latest version' do
            response = subject.find_all(
              account: 'rspec',
              role: ::Role[role_id]
            )
            expect(response.success?).to eq(true)
            expect(response.result.count).to eq(1)
            expect(response.result.first.version).to eq('v10')
          end
        end
      end
      context 'when some factories are empty' do
        before(:each) do
          ::Resource.create(resource_id: factory1, owner_id: role_id)
          ::Resource.create(resource_id: factory2, owner_id: role_id)
          ::Secret.create(
            resource_id: factory2,
            value: Factories::Templates::Core::V1::User.data
          )
        end
        after(:each) do
          ::Resource[factory1].destroy
          ::Resource[factory2].destroy
        end
        it 'does not return empty factories' do
          response = subject.find_all(
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(true)
          expect(response.result.count).to eq(1)
          expect(response.result.first.name).to eq('user')
        end
      end
      context 'when all factories are empty' do
        # TODO: this error is a bit weird...  I'd expect a specific error if no factories were configured.
        before(:each) do
          ::Resource.create(resource_id: factory1, owner_id: role_id)
          ::Resource.create(resource_id: factory2, owner_id: role_id)
        end
        after(:each) do
          ::Resource[factory1].destroy
          ::Resource[factory2].destroy
        end
        it 'does not return any factories' do
          response = subject.find_all(
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(false)
          expect(response.status).to eq(:forbidden)
          expect(response.message).to eq('Role does not have permission to use Factories')
        end
      end
    end
  end

  describe '.find' do
    context 'when factory does not exist' do
      before(:each) do
        ::Role.create(role_id: 'rspec:group:conjur/policy-factory-users')
      end
      after(:each) do
        ::Role['rspec:group:conjur/policy-factory-users'].destroy
      end
      it 'returns an error' do
        response = subject.find(
          kind: 'foo',
          id: 'bar',
          account: 'foo-bar',
          role: ::Role['rspec:group:conjur/policy-factory-users']
        )
        expect(response.success?).to eq(false)
        expect(response.status).to eq(:not_found)
        expect(response.message).to include(
          {
            resource: 'foo/v1/bar',
            message: 'Requested Policy Factory does not exist'
          }
        )
      end
    end
    context 'when factory exists' do
      context 'when requesting role does not have permission' do
        let(:role_id) { 'rspec:group:conjur/policy-factory-users' }
        let(:resource_id) { 'rspec:variable:conjur/factories/core/v1/group' }
        before(:each) do
          ::Role.create(role_id: role_id)
          admin = ::Role.create(role_id: 'rspec:user:policy_admin')
          ::Resource.create(resource_id: resource_id, owner: admin)
        end
        after(:each) do
          ::Role[role_id].destroy
          ::Resource[resource_id].destroy
          ::Role['rspec:user:policy_admin'].destroy
        end
        it 'returns an error' do
          response = subject.find(
            kind: 'core',
            id: 'group',
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(false)
          expect(response.status).to eq(:forbidden)
          expect(response.message).to include(
            {
              resource: 'core/v1/group',
              message: 'Requested Policy Factory is not available'
            }
          )
        end
      end
      context 'when factory is empty' do
        let(:role_id) { 'rspec:group:conjur/policy-factory-users' }
        let(:resource_id) { 'rspec:variable:conjur/factories/core/v1/group' }
        before(:each) do
          ::Role.create(role_id: role_id)
          ::Resource.create(resource_id: resource_id, owner_id: role_id)
        end
        after(:each) do
          ::Resource[resource_id].destroy
          ::Role[role_id].destroy
        end
        it 'returns an error' do
          response = subject.find(
            kind: 'core',
            id: 'group',
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(false)
          expect(response.status).to eq(:bad_request)
          expect(response.message).to include(
            {
              resource: 'core/v1/group',
              message: 'Requested Policy Factory is not available'
            }
          )
        end
      end
      context 'requesting role has permission' do
        let(:role_id) { 'rspec:group:conjur/policy-factory-users' }
        let(:resource_id) { 'rspec:variable:conjur/factories/core/v1/group' }
        before(:each) do
          ::Role.create(role_id: role_id)
          ::Resource.create(resource_id: resource_id, owner_id: role_id)
          ::Secret.create(
            resource_id: resource_id,
            value: Factories::Templates::Core::V1::Group.data
          )
        end
        after(:each) do
          ::Resource[resource_id].destroy
          ::Role[role_id].destroy
        end
        it 'returns the policy factory' do
          response = subject.find(
            kind: 'core',
            id: 'group',
            account: 'rspec',
            role: ::Role[role_id]
          )
          expect(response.success?).to eq(true)
          expect(response.result.class).to eq(DB::Repository::DataObjects::PolicyFactory)
          expect(response.result.name).to eq('group')
        end
        context 'when description attribute is missing' do
          before(:each) do
            data = Factories::Templates::Core::V1::Group.data
            decoded_data = JSON.parse(Base64.decode64(data))
            decoded_data['schema'].delete('description')

            ::Secret.create(
              resource_id: resource_id,
              value: Base64.encode64(decoded_data.to_json)
            )
          end
          it 'includes an empty description' do
            response = subject.find(
              kind: 'core',
              id: 'group',
              account: 'rspec',
              role: ::Role[role_id]
            )
            expect(response.success?).to eq(true)
            expect(response.result.description).to eq('')
          end
        end
      end
      context 'when multiple versions exist' do
        let(:owner_id) { 'rspec:group:conjur/policy-factory-users' }
        let(:version1) { 'rspec:variable:conjur/factories/core/v1/group' }
        let(:version2) { 'rspec:variable:conjur/factories/core/v2/group' }
        before(:each) do
          ::Role.create(role_id: owner_id)
          ::Resource.create(resource_id: version1, owner_id: owner_id)
          ::Secret.create(
            resource_id: version1,
            value: Factories::Templates::Core::V1::Group.data
          )
          ::Resource.create(resource_id: version2, owner_id: owner_id)
          ::Secret.create(
            resource_id: version2,
            value: Factories::Templates::Core::V1::Group.data
          )
        end
        after(:each) do
          ::Resource[version1].destroy
          ::Resource[version2].destroy
          ::Role[owner_id].destroy
        end
        context 'when no version is provided' do
          it 'returns the latest version' do
            response = subject.find(
              kind: 'core',
              id: 'group',
              account: 'rspec',
              role: ::Role[owner_id]
            )
            expect(response.success?).to eq(true)
            expect(response.result.version).to eq('v2')
          end
        end
        context 'when a version is provided' do
          it 'returns the requested version' do
            response = subject.find(
              kind: 'core',
              id: 'group',
              account: 'rspec',
              role: ::Role[owner_id],
              version: 'v1'
            )
            expect(response.success?).to eq(true)
            expect(response.result.version).to eq('v1')
          end
        end

        context 'when there are more than 10 factory versions' do
          let(:version1) { 'rspec:variable:conjur/factories/core/v9/group' }
          let(:version2) { 'rspec:variable:conjur/factories/core/v10/group' }
          it 'returns the latest version' do
            response = subject.find(
              kind: 'core',
              id: 'group',
              account: 'rspec',
              role: ::Role[owner_id]
            )
            expect(response.success?).to eq(true)
            expect(response.result.version).to eq('v10')
          end
        end

      end
    end
  end
end
