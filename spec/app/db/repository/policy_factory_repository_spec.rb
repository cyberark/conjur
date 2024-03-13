# frozen_string_literal: true

require 'spec_helper'

# Factories generated from the Factory
def user_factory
  # rubocop:disable Layout/LineLength
  'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoZFhObGNnb2dJR2xrT2lBOEpUMGdhV1FnSlQ0S1BDVWdhV1lnWkdWbWFXNWxaRDhvYjNkdVpYSmZjbTlzWlNrZ0ppWWdaR1ZtYVc1bFpEOG9iM2R1WlhKZmRIbHdaU2tnTFNVK0NpQWdiM2R1WlhJNklDRThKVDBnYjNkdVpYSmZkSGx3WlNBbFBpQThKVDBnYjNkdVpYSmZjbTlzWlNBbFBnbzhKU0JsYm1RZ0xTVStDandsSUdsbUlHUmxabWx1WldRL0tHbHdYM0poYm1kbEtTQXRKVDRLSUNCeVpYTjBjbWxqZEdWa1gzUnZPaUE4SlQwZ2FYQmZjbUZ1WjJVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiVXNlciBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQ3JlYXRlcyBhIENvbmp1ciBVc2VyIiwidHlwZSI6Im9iamVjdCIsInByb3BlcnRpZXMiOnsiaWQiOnsiZGVzY3JpcHRpb24iOiJVc2VyIElEIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHVzZXIgaW50byIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfcm9sZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBDb25qdXIgUm9sZSB0aGF0IHdpbGwgb3duIHRoaXMgdXNlciIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfdHlwZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSByZXNvdXJjZSB0eXBlIG9mIHRoZSBvd25lciBvZiB0aGlzIHVzZXIiLCJ0eXBlIjoic3RyaW5nIn0sImlwX3JhbmdlIjp7ImRlc2NyaXB0aW9uIjoiTGltaXRzIHRoZSBuZXR3b3JrIHJhbmdlIHRoZSB1c2VyIGlzIGFsbG93ZWQgdG8gYXV0aGVudGljYXRlIGZyb20iLCJ0eXBlIjoic3RyaW5nIn19LCJyZXF1aXJlZCI6WyJicmFuY2giLCJpZCJdfX0='
  # rubocop:enable Layout/LineLength
end

def group_factory
  # rubocop:disable Layout/LineLength
  'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoWjNKdmRYQUtJQ0JwWkRvZ1BDVTlJR2xrSUNVK0Nqd2xJR2xtSUdSbFptbHVaV1EvS0c5M2JtVnlYM0p2YkdVcElDWW1JR1JsWm1sdVpXUS9LRzkzYm1WeVgzUjVjR1VwSUMwbFBnb2dJRzkzYm1WeU9pQWhQQ1U5SUc5M2JtVnlYM1I1Y0dVZ0pUNGdQQ1U5SUc5M2JtVnlYM0p2YkdVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiR3JvdXAgVGVtcGxhdGUiLCJkZXNjcmlwdGlvbiI6IkNyZWF0ZXMgYSBDb25qdXIgR3JvdXAiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJpZCI6eyJkZXNjcmlwdGlvbiI6Ikdyb3VwIElkZW50aWZpZXIiLCJ0eXBlIjoic3RyaW5nIn0sImFubm90YXRpb25zIjp7ImRlc2NyaXB0aW9uIjoiQWRkaXRpb25hbCBhbm5vdGF0aW9ucyIsInR5cGUiOiJvYmplY3QifSwiYnJhbmNoIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IGJyYW5jaCB0byBsb2FkIHRoaXMgcmVzb3VyY2UgaW50byIsInR5cGUiOiJzdHJpbmcifSwib3duZXJfcm9sZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBDb25qdXIgUm9sZSB0aGF0IHdpbGwgb3duIHRoaXMgZ3JvdXAiLCJ0eXBlIjoic3RyaW5nIn0sIm93bmVyX3R5cGUiOnsiZGVzY3JpcHRpb24iOiJUaGUgcmVzb3VyY2UgdHlwZSBvZiB0aGUgb3duZXIgb2YgdGhpcyBncm91cCIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbImJyYW5jaCIsImlkIl19fQ=='
  # rubocop:enable Layout/LineLength
end

RSpec.describe(DB::Repository::PolicyFactoryRepository) do
  # Ensure the variables below have not been set in previous tests
  before(:all) do
    ::Resource['rspec:variable:conjur/factories/core/v1/group']&.destroy
    ::Resource['rspec:variable:conjur/factories/core/v1/user']&.destroy
    ::Resource['rspec:variable:conjur/factories/core/v1/bad']&.destroy
  end
  subject { DB::Repository::PolicyFactoryRepository.new }

  describe '.find_all' do
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
        expect(response.message).to eq('Role does not have permission to use Factories, or, no Factories are available')
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
            value: group_factory
          )
          ::Resource.create(resource_id: factory2, owner_id: owner_id)
          ::Secret.create(
            resource_id: factory2,
            value: user_factory
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
          expect(response.message).to eq('Role does not have permission to use Factories, or, no Factories are available')
        end
      end
      context 'when role has execute permission on some factories' do
        let(:owner_id) { 'rspec:group:admin' }
        before(:each) do
          ::Role.create(role_id: owner_id)
          ::Resource.create(resource_id: factory1, owner_id: role_id)
          ::Secret.create(
            resource_id: factory1,
            value: group_factory
          )
          ::Resource.create(resource_id: factory2, owner_id: owner_id)
          ::Secret.create(
            resource_id: factory2,
            value: user_factory
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
            value: group_factory
          )
          ::Resource.create(resource_id: factory2, owner_id: role_id)
          ::Secret.create(
            resource_id: factory2,
            value: user_factory
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
            value: group_factory
          )
          ::Resource.create(resource_id: factory2, owner_id: role_id)
          ::Secret.create(
            resource_id: factory2,
            value: group_factory
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
            value: user_factory
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
          expect(response.message).to eq('Role does not have permission to use Factories, or, no Factories are available')
        end
      end
      context 'when a factory variables contain invalid values' do
        let(:bad_factory) { 'rspec:variable:conjur/factories/core/v1/bad' }
        before(:each) do
          ::Resource.create(resource_id: factory1, owner_id: role_id)
          ::Secret.create(resource_id: factory1, value: group_factory)
          ::Resource.create(resource_id: factory2, owner_id: role_id)
          ::Secret.create(resource_id: factory2, value: user_factory)
          ::Resource.create(resource_id: bad_factory, owner_id: role_id)
        end
        after(:each) do
          ::Resource[factory1].destroy
          ::Resource[factory2].destroy
          ::Resource[bad_factory].destroy
        end
        context 'when the bad factory is invalid json' do
          before(:each) do
            ::Secret.create(resource_id: bad_factory, value: 'lksjdf')
          end
          it 'does not return the bad factory' do
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
        context 'when the bad factory is valid json' do
          before(:each) do
            ::Secret.create(resource_id: bad_factory, value: { foo: 'bar' }.to_json)
          end
          it 'does not return the bad factory' do
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
      context 'when the requesting role has permission' do
        let(:role_id) { 'rspec:group:conjur/policy-factory-users' }
        let(:resource_id) { 'rspec:variable:conjur/factories/core/v1/group' }
        context 'when factory is empty' do
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
        context 'when the factory is present' do
          let(:resource_id) { 'rspec:variable:conjur/factories/core/v1/group' }
          before(:each) do
            ::Role.create(role_id: role_id)
            ::Resource.create(resource_id: resource_id, owner_id: role_id)
            ::Secret.create(
              resource_id: resource_id,
              value: group_factory
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
            expect(response.result.description).to eq('Creates a Conjur Group')
            expect(response.result.variables).to eq({})
          end
          context 'when description attribute is missing' do
            before(:each) do
              data = group_factory
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
          context 'when multiple versions exist' do
            let(:version1) { 'rspec:variable:conjur/factories/core/v2/group' }
            let(:version2) { 'rspec:variable:conjur/factories/core/v3/group' }
            before(:each) do
              ::Resource.create(resource_id: version1, owner_id: role_id)
              ::Secret.create(
                resource_id: version1,
                value: group_factory
              )
              ::Resource.create(resource_id: version2, owner_id: role_id)
              ::Secret.create(
                resource_id: version2,
                value: group_factory
              )
            end
            after(:each) do
              ::Resource[version1]&.destroy
              ::Resource[version2]&.destroy
            end
            context 'when no version is provided' do
              it 'returns the latest version' do
                response = subject.find(
                  kind: 'core',
                  id: 'group',
                  account: 'rspec',
                  role: ::Role[role_id]
                )
                expect(response.success?).to eq(true)
                expect(response.result.version).to eq('v3')
              end
            end
            context 'when a version is provided' do
              it 'returns the requested version' do
                response = subject.find(
                  kind: 'core',
                  id: 'group',
                  account: 'rspec',
                  role: ::Role[role_id],
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
                  role: ::Role[role_id]
                )
                expect(response.success?).to eq(true)
                expect(response.result.version).to eq('v10')
              end
            end
          end
          context 'when factory variable data is not a valid factory' do
            let(:bad_factory) { 'rspec:variable:conjur/factories/core/v1/bad' }
            before(:each) do
              ::Resource.create(resource_id: bad_factory, owner_id: role_id)
            end
            after(:each) do
              ::Resource[bad_factory].destroy
            end
            context 'when the factory variable is invalid json' do
              before(:each) do
                ::Secret.create(resource_id: bad_factory, value: 'lksjdf')
              end
              it 'returns an error' do
                response = subject.find(
                  kind: 'core',
                  id: 'bad',
                  account: 'rspec',
                  role: ::Role[role_id]
                )
                expect(response.success?).to eq(false)
                expect(response.status).to eq(:service_unavailable)
                expect(response.message).to eq("Failed to decode Factory: 'bad'")
              end
            end
            context 'when the factory variable is valid json but not a valid factory' do
              before(:each) do
                ::Secret.create(resource_id: bad_factory, value: { foo: 'bar' }.to_json)
              end
              it 'returns an error' do
                response = subject.find(
                  kind: 'core',
                  id: 'bad',
                  account: 'rspec',
                  role: ::Role[role_id]
                )
                expect(response.success?).to eq(false)
                expect(response.status).to eq(:service_unavailable)
                expect(response.message).to eq("Failed to decode Factory: 'bad'")
              end
            end
          end
        end
        context 'when a factory variable does not include a version' do
          let(:resource_id) { 'rspec:variable:conjur/factories/core/group' }
          before(:each) do
            ::Role.create(role_id: role_id)
            ::Resource.create(resource_id: resource_id, owner_id: role_id)
            ::Secret.create(
              resource_id: resource_id,
              value: group_factory
            )
          end
          after(:each) do
            ::Resource[resource_id].destroy
            ::Role[role_id].destroy
          end
          it 'does not show up in results' do
            response = subject.find(
              kind: 'core',
              id: 'group',
              account: 'rspec',
              role: ::Role[role_id]
            )
            expect(response.success?).to eq(false)
            expect(response.status).to eq(:not_found)
          end
        end
      end
    end
  end
end
