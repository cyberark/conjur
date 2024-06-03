# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe PoliciesController, type: :request do
  describe '#patch' do
    context 'when policy includes a delete operation' do
      context 'for a policy' do
        it 'removes all roles and resources inside that policy' do
          role_resource_ids = ['rspec:policy:data', 'rspec:user:alice@data', 'rspec:host:data/host-01']

          # Apply Policy with role w/ corresponding resource
          apply_policy(
            policy: <<~TEMPLATE
              - !policy
                id: data
                body:
                - !user alice
                - !host host-01
            TEMPLATE
          )

          # Verify desired resources and roles have been created
          role_resource_ids.each do |id|
            expect(Role[id]).to_not be(nil)
            expect(Resource[id]).to_not be(nil)
          end

          # Now, delete the above roles and resources by deleting the policy
          apply_policy(
            action: :patch,
            policy: <<~TEMPLATE
              - !delete
                record: !policy data
            TEMPLATE
          )

          # Verify desired resources and roles have been removed
          role_resource_ids.each do |id|
            expect(Role[id]).to be(nil)
            expect(Resource[id]).to be(nil)
          end
        end

        it 'deletes all roles and resources owned by the deletor in that policy' do
          deleted_role_resource_ids = [
            'rspec:policy:data/subdata-1',
            'rspec:user:bob@data-subdata-1',
            'rspec:host:data/subdata-1/host-02'
          ]

          # Apply Policy with role w/ corresponding resource
          apply_policy(
            policy: <<~TEMPLATE
              - !user foo
              - !user bar
              - !policy
                id: data
                owner: !user bar
                body:
                - !policy
                  id: subdata-1
                  body:
                    - !user bob
                    - !host host-02
                    - !policy
                      id: subdata-2
                      owner: !user /foo
                      body:
                        - !user fred
                        - !host host-03
            TEMPLATE
          )
          # Verify desired resources and roles have been created
          deleted_role_resource_ids.each do |id|
            expect(Role[id]).to_not be(nil)
            expect(Resource[id]).to_not be(nil)
          end

          # Now, delete the above roles and resources by deleting the policy
          apply_policy(
            action: :patch,
            policy_branch: 'data',
            role: 'bar',
            policy: <<~TEMPLATE
              - !delete
                record: !policy subdata-1
            TEMPLATE
          )

          # Verify desired resources and roles have been removed
          deleted_role_resource_ids.each do |id|
            expect(Role[id]).to be(nil)
            expect(Resource[id]).to be(nil)
          end
        end
      end
    end
  end
end
