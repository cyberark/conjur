# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Loader::ReplacePolicy) do
  # When a Loader is called, a PolicyResult is returned.
  let(:policy_result) { ::PolicyResult }
  let(:policy_version) { nil }
  let(:logger) { nil }

  let(:subject) do
    Loader::ReplacePolicy.from_policy(
      policy_parse,
      policy_version,
      policy_loader_class,
      policy_diff: policy_diff,
      policy_repository: policy_repository,
      policy_result: policy_result,
      logger: logger
    )
  end

  let(:policy_parse) do
    PolicyParse.new([], nil)
  end

  let(:policy_loader) do
    Loader::DryRun.new(policy_parse: policy_parse, policy_version: policy_version, logger: logger).tap do |loader|
      # These methods are called during the policy loading procedures.
      allow(loader).to receive(:setup_db_for_new_policy).and_return(nil)
      allow(loader).to receive(:delete_removed).and_return(nil)
      allow(loader).to receive(:delete_shadowed_and_duplicate_rows).and_return(nil)
      allow(loader).to receive(:upsert_policy_records).and_return(nil)
      allow(loader).to receive(:clean_db).and_return(nil)
      allow(loader).to receive(:store_auxiliary_data).and_return(nil)
      allow(loader).to receive(:store_policy_in_db).and_return(nil)
      allow(loader).to receive(:release_db_connection).and_return(nil)

      # These methods are called after a policy load to assert whether a policy
      # validation error occurred.
      allow(loader).to receive(:policy_parse).and_return(nil)
      allow(loader).to receive(:policy_version).and_return(nil)

      # These methods are called when a PolicyResult is initialized with
      # credential_roles.
      allow(loader).to receive(:actor_roles).and_return(nil)
      allow(loader).to receive(:credential_roles).and_return(nil)
    end
  end

  let(:policy_loader_class) do
    class_double(Loader::DryRun).tap do |double|
      allow(double).to receive(:new).with(
        policy_parse: policy_parse,
        policy_version: policy_version,
        logger: logger
      ).and_return(policy_loader)
    end
  end

  # These entities are returned from the PolicyRepository.
  let(:annotations) do 
    [
      {
        "resource_id": "cucumber:user:barrett@example",
        "name": "key",
        "value": "value",
        "policy_id": "cucumber:policy:root"
      }
    ]
  end

  let(:credentials) do 
    [
      {
        "role_id": "cucumber:user:barrett@example",
        "client_id": nil,
        "restricted_to": [
          "127.0.0.1"
        ]
      }
    ]
  end

  let(:permissions) do 
    [
      {
        "privilege": "execute",
        "resource_id": "cucumber:variable:example/secret01",
        "role_id": "cucumber:group:example/secret-users",
        "policy_id": "cucumber:policy:root"
      }
    ]
  end

  let(:resources) do 
    [
      {
        "resource_id": "cucumber:user:barrett@example",
        "owner_id": "cucumber:policy:example",
        "policy_id": "cucumber:policy:root"
      }
    ]
  end

  let(:role_memberships) do 
    [
      {
        "role_id": "cucumber:user:barrett@example",
        "member_id": "cucumber:policy:example",
        "admin_option": true,
        "ownership": true,
        "policy_id": "cucumber:policy:root"
      }
    ]
  end

  let(:roles) do 
    [
      {
        "role_id": "cucumber:user:barrett@example",
        "policy_id": "cucumber:policy:root"
      }
    ]
  end

  let(:db) do
    instance_double('Sequel::Postgres::Database').tap do |double|
      allow(double).to receive(:execute).with(anything).and_return(nil)
      allow(double).to receive(:fetch).with(anything).and_return([])
      allow(double).to receive(:search_path=).with(anything)
    end
  end

  let(:policy_repository) do
    DB::Repository::PolicyRepository.new(db: db).tap do |repo|
      allow(repo).to receive(:find_created_elements)
        .with(anything)
        .and_return(diff_response)
      allow(repo).to receive(:find_deleted_elements)
        .with(anything)
        .and_return(diff_response)
      allow(repo).to receive(:find_original_elements)
        .with(anything)
        .and_return(diff_response)
    end
  end

  let(:diff_response) do
    DB::Repository::DataObjects::DiffElements.new(
      annotations: annotations,
      credentials: credentials,
      permissions: permissions,
      resources: resources,
      role_memberships: role_memberships,
      roles: roles
    )
  end

  let(:policy_diff_response) do
    ::SuccessResponse.new({
      created: diff_response,
      deleted: diff_response,
      updated: diff_response,
      final: diff_response
    })
  end

  let(:policy_diff) do
    CommandHandler::PolicyDiff.new(policy_repository: policy_repository).tap do |mock|
      allow(mock).to receive(:call)
        .and_return(policy_diff_response)
    end
  end

  describe '.call' do
    context 'when a policy is loaded with dryrun' do
      context 'when the diff schema name is nil' do
        before do
          allow(policy_loader).to receive(:diff_schema_name)
            .and_return(nil)
        end
        
        it 'there is no diff result' do
          result = subject.call  
          expect(result.nil?).to eq(false)
          expect(result.policy_parse.nil?).to eq(true)
          expect(result.policy_version).to eq(nil)
          expect(result.created_roles).to eq(nil)
          expect(result.diff).to eq(nil)
        end
      end
  
      context 'when the diff schema name is provided' do
        before do
          allow(policy_loader).to receive(:load_records)
            .and_return(nil)
        end

        context 'when the diff query contains only annotations' do
          let(:credentials) { [] }
          let(:permissions) { [] }
          let(:resources) { [] }
          let(:role_memberships) { [] }
          let(:roles) { [] }

          it 'the diff result includes the annotations' do
            result = subject.call

            # The PoliyResult is valid
            expect(result.nil?).to eq(false)
            expect(result.policy_parse.nil?).to eq(true)
            expect(result.policy_version).to eq(nil)
            expect(result.created_roles).to eq(nil)

            # PolicyResult contains a diff
            expect(result.diff).to be_a(Hash)
            expect(result.diff).to include(:created, :deleted, :updated) 

            expect(result.diff[:created])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:created].annotations.length).to eq(1)
            expect(result.diff[:created].credentials.length).to eq(0)
            expect(result.diff[:created].permissions.length).to eq(0)
            expect(result.diff[:created].resources.length).to eq(0)
            expect(result.diff[:created].role_memberships.length).to eq(0)
            expect(result.diff[:created].roles.length).to eq(0)

            expect(result.diff[:deleted])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:deleted].annotations.length).to eq(1)
            expect(result.diff[:deleted].credentials.length).to eq(0)
            expect(result.diff[:deleted].permissions.length).to eq(0)
            expect(result.diff[:deleted].resources.length).to eq(0)
            expect(result.diff[:deleted].role_memberships.length).to eq(0)
            expect(result.diff[:deleted].roles.length).to eq(0)

            expect(result.diff[:updated])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:updated].annotations.length).to eq(1)
            expect(result.diff[:updated].credentials.length).to eq(0)
            expect(result.diff[:updated].permissions.length).to eq(0)
            expect(result.diff[:updated].resources.length).to eq(0)
            expect(result.diff[:updated].role_memberships.length).to eq(0)
            expect(result.diff[:updated].roles.length).to eq(0)
          end
        end

        context 'when the diff query contains only credentials' do
          let(:annotations) { [] }
          let(:permissions) { [] }
          let(:resources) { [] }
          let(:role_memberships) { [] }
          let(:roles) { [] }

          it 'the diff result includes the credentials' do
            result = subject.call

            # The PoliyResult is valid
            expect(result.nil?).to eq(false)
            expect(result.policy_parse.nil?).to eq(true)
            expect(result.policy_version).to eq(nil)
            expect(result.created_roles).to eq(nil)

            # PolicyResult contains a diff
            expect(result.diff).to be_a(Hash)
            expect(result.diff).to include(:created, :deleted, :updated) 

            expect(result.diff[:created])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:created].annotations.length).to eq(0)
            expect(result.diff[:created].credentials.length).to eq(1)
            expect(result.diff[:created].permissions.length).to eq(0)
            expect(result.diff[:created].resources.length).to eq(0)
            expect(result.diff[:created].role_memberships.length).to eq(0)
            expect(result.diff[:created].roles.length).to eq(0)

            expect(result.diff[:deleted])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:deleted].annotations.length).to eq(0)
            expect(result.diff[:deleted].credentials.length).to eq(1)
            expect(result.diff[:deleted].permissions.length).to eq(0)
            expect(result.diff[:deleted].resources.length).to eq(0)
            expect(result.diff[:deleted].role_memberships.length).to eq(0)
            expect(result.diff[:deleted].roles.length).to eq(0)

            expect(result.diff[:updated])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:updated].annotations.length).to eq(0)
            expect(result.diff[:updated].credentials.length).to eq(1)
            expect(result.diff[:updated].permissions.length).to eq(0)
            expect(result.diff[:updated].resources.length).to eq(0)
            expect(result.diff[:updated].role_memberships.length).to eq(0)
            expect(result.diff[:updated].roles.length).to eq(0)
          end
        end

        context 'when the diff query contains only permissions' do
          let(:annotations) { [] }
          let(:credentials) { [] }
          let(:resources) { [] }
          let(:role_memberships) { [] }
          let(:roles) { [] }

          it 'the diff result includes the permissions' do
            result = subject.call

            # The PoliyResult is valid
            expect(result.nil?).to eq(false)
            expect(result.policy_parse.nil?).to eq(true)
            expect(result.policy_version).to eq(nil)
            expect(result.created_roles).to eq(nil)

            # PolicyResult contains a diff
            expect(result.diff).to be_a(Hash)
            expect(result.diff).to include(:created, :deleted, :updated) 

            expect(result.diff[:created])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:created].annotations.length).to eq(0)
            expect(result.diff[:created].credentials.length).to eq(0)
            expect(result.diff[:created].permissions.length).to eq(1)
            expect(result.diff[:created].resources.length).to eq(0)
            expect(result.diff[:created].role_memberships.length).to eq(0)
            expect(result.diff[:created].roles.length).to eq(0)

            expect(result.diff[:deleted])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:deleted].annotations.length).to eq(0)
            expect(result.diff[:deleted].credentials.length).to eq(0)
            expect(result.diff[:deleted].permissions.length).to eq(1)
            expect(result.diff[:deleted].resources.length).to eq(0)
            expect(result.diff[:deleted].role_memberships.length).to eq(0)
            expect(result.diff[:deleted].roles.length).to eq(0)

            expect(result.diff[:updated])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:updated].annotations.length).to eq(0)
            expect(result.diff[:updated].credentials.length).to eq(0)
            expect(result.diff[:updated].permissions.length).to eq(1)
            expect(result.diff[:updated].resources.length).to eq(0)
            expect(result.diff[:updated].role_memberships.length).to eq(0)
            expect(result.diff[:updated].roles.length).to eq(0)
          end
        end

        context 'when the diff query contains only resources' do
          let(:annotations) { [] }
          let(:credentials) { [] }
          let(:permissions) { [] }
          let(:role_memberships) { [] }
          let(:roles) { [] }

          it 'the diff result includes the resources' do
            result = subject.call

            # The PoliyResult is valid
            expect(result.nil?).to eq(false)
            expect(result.policy_parse.nil?).to eq(true)
            expect(result.policy_version).to eq(nil)
            expect(result.created_roles).to eq(nil)

            # PolicyResult contains a diff
            expect(result.diff).to be_a(Hash)
            expect(result.diff).to include(:created, :deleted, :updated) 

            expect(result.diff[:created])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:created].annotations.length).to eq(0)
            expect(result.diff[:created].credentials.length).to eq(0)
            expect(result.diff[:created].permissions.length).to eq(0)
            expect(result.diff[:created].resources.length).to eq(1)
            expect(result.diff[:created].role_memberships.length).to eq(0)
            expect(result.diff[:created].roles.length).to eq(0)

            expect(result.diff[:deleted])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:deleted].annotations.length).to eq(0)
            expect(result.diff[:deleted].credentials.length).to eq(0)
            expect(result.diff[:deleted].permissions.length).to eq(0)
            expect(result.diff[:deleted].resources.length).to eq(1)
            expect(result.diff[:deleted].role_memberships.length).to eq(0)
            expect(result.diff[:deleted].roles.length).to eq(0)

            expect(result.diff[:updated])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:updated].annotations.length).to eq(0)
            expect(result.diff[:updated].credentials.length).to eq(0)
            expect(result.diff[:updated].permissions.length).to eq(0)
            expect(result.diff[:updated].resources.length).to eq(1)
            expect(result.diff[:updated].role_memberships.length).to eq(0)
            expect(result.diff[:updated].roles.length).to eq(0)
          end
        end

        context 'when the diff query contains only role memberships' do
          let(:annotations) { [] }
          let(:credentials) { [] }
          let(:permissions) { [] }
          let(:resources) { [] }
          let(:roles) { [] }

          it 'the diff result includes the role memberships' do
            result = subject.call

            # The PoliyResult is valid
            expect(result.nil?).to eq(false)
            expect(result.policy_parse.nil?).to eq(true)
            expect(result.policy_version).to eq(nil)
            expect(result.created_roles).to eq(nil)

            # PolicyResult contains a diff
            expect(result.diff).to be_a(Hash)
            expect(result.diff).to include(:created, :deleted, :updated) 

            expect(result.diff[:created])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:created].annotations.length).to eq(0)
            expect(result.diff[:created].credentials.length).to eq(0)
            expect(result.diff[:created].permissions.length).to eq(0)
            expect(result.diff[:created].resources.length).to eq(0)
            expect(result.diff[:created].role_memberships.length).to eq(1)
            expect(result.diff[:created].roles.length).to eq(0)

            expect(result.diff[:deleted])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:deleted].annotations.length).to eq(0)
            expect(result.diff[:deleted].credentials.length).to eq(0)
            expect(result.diff[:deleted].permissions.length).to eq(0)
            expect(result.diff[:deleted].resources.length).to eq(0)
            expect(result.diff[:deleted].role_memberships.length).to eq(1)
            expect(result.diff[:deleted].roles.length).to eq(0)

            expect(result.diff[:updated])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:updated].annotations.length).to eq(0)
            expect(result.diff[:updated].credentials.length).to eq(0)
            expect(result.diff[:updated].permissions.length).to eq(0)
            expect(result.diff[:updated].resources.length).to eq(0)
            expect(result.diff[:updated].role_memberships.length).to eq(1)
            expect(result.diff[:updated].roles.length).to eq(0)
          end
        end

        context 'when the diff query contains only roles' do
          let(:annotations) { [] }
          let(:credentials) { [] }
          let(:permissions) { [] }
          let(:resources) { [] }
          let(:role_memberships) { [] }

          it 'the diff result includes the roles' do
            result = subject.call

            # The PoliyResult is valid
            expect(result.nil?).to eq(false)
            expect(result.policy_parse.nil?).to eq(true)
            expect(result.policy_version).to eq(nil)
            expect(result.created_roles).to eq(nil)

            # PolicyResult contains a diff
            expect(result.diff).to be_a(Hash)
            expect(result.diff).to include(:created, :deleted, :updated) 

            expect(result.diff[:created])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:created].annotations.length).to eq(0)
            expect(result.diff[:created].credentials.length).to eq(0)
            expect(result.diff[:created].permissions.length).to eq(0)
            expect(result.diff[:created].resources.length).to eq(0)
            expect(result.diff[:created].role_memberships.length).to eq(0)
            expect(result.diff[:created].roles.length).to eq(1)

            expect(result.diff[:deleted])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:deleted].annotations.length).to eq(0)
            expect(result.diff[:deleted].credentials.length).to eq(0)
            expect(result.diff[:deleted].permissions.length).to eq(0)
            expect(result.diff[:deleted].resources.length).to eq(0)
            expect(result.diff[:deleted].role_memberships.length).to eq(0)
            expect(result.diff[:deleted].roles.length).to eq(1)

            expect(result.diff[:updated])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:updated].annotations.length).to eq(0)
            expect(result.diff[:updated].credentials.length).to eq(0)
            expect(result.diff[:updated].permissions.length).to eq(0)
            expect(result.diff[:updated].resources.length).to eq(0)
            expect(result.diff[:updated].role_memberships.length).to eq(0)
            expect(result.diff[:updated].roles.length).to eq(1)
          end
        end

        context 'when there is a diff containing every attribute' do
          it 'the diff result is full' do
            result = subject.call

            # The PoliyResult is valid
            expect(result.nil?).to eq(false)
            expect(result.policy_parse.nil?).to eq(true)
            expect(result.policy_version).to eq(nil)
            expect(result.created_roles).to eq(nil)

            # PolicyResult contains a diff
            expect(result.diff).to be_a(Hash)
            expect(result.diff).to include(:created, :deleted, :updated) 

            expect(result.diff[:created])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:created].annotations.length).to eq(1)
            expect(result.diff[:created].credentials.length).to eq(1)
            expect(result.diff[:created].permissions.length).to eq(1)
            expect(result.diff[:created].resources.length).to eq(1)
            expect(result.diff[:created].role_memberships.length).to eq(1)
            expect(result.diff[:created].roles.length).to eq(1)

            expect(result.diff[:deleted])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:deleted].annotations.length).to eq(1)
            expect(result.diff[:deleted].credentials.length).to eq(1)
            expect(result.diff[:deleted].permissions.length).to eq(1)
            expect(result.diff[:deleted].resources.length).to eq(1)
            expect(result.diff[:deleted].role_memberships.length).to eq(1)
            expect(result.diff[:deleted].roles.length).to eq(1)

            expect(result.diff[:updated])
              .to be_a(DB::Repository::DataObjects::DiffElements)
            expect(result.diff[:updated].annotations.length).to eq(1)
            expect(result.diff[:updated].credentials.length).to eq(1)
            expect(result.diff[:updated].permissions.length).to eq(1)
            expect(result.diff[:updated].resources.length).to eq(1)
            expect(result.diff[:updated].role_memberships.length).to eq(1)
            expect(result.diff[:updated].roles.length).to eq(1)
          end
        end
      end
    end
  end

  describe '.call_pr' do
    context 'when a policy is loaded with dryrun' do
      context 'when it is called with a policy result' do
        let(:mock_policy_result_input) { instance_double('PolicyResult') }
        let(:mock_policy_result_output) do
          double(
            created_roles: %w[role1 role2],
            diff: diff_response
          )
        end
  
        before do
          allow(mock_policy_result_input).to receive(:created_roles=).and_return(nil)
          allow(mock_policy_result_input).to receive(:diff=).and_return(nil)
        end
      
        it 'receives .call and assigns created_roles and diff' do
          expect(subject).to receive(:call).and_return(mock_policy_result_output)
          expect(mock_policy_result_input).to receive(:created_roles=).with(%w[role1 role2])
          expect(mock_policy_result_input).to receive(:diff=).with(diff_response)
      
          subject.call_pr(mock_policy_result_input)
        end
      end
    end
  end

  describe '.report' do
    context 'when a policy is loaded with dryrun' do
      context 'when report is called given a policy result' do
        let(:policy_result) { instance_double('PolicyResult') }    
  
        before do
          allow(policy_result).to receive(:diff).and_return(nil)
          allow(policy_result).to receive(:policy_parse).and_return(nil)
          allow(policy_loader).to receive(:load_records).and_return(nil)
          allow(policy_loader).to receive(:report).and_call_original
        end
  
        context 'and the policy result contains an error' do
          let(:validation_error) do 
            Exceptions::EnhancedPolicyError.new(
              original_error: nil,
              detail_message: "fake error"
            )
          end
  
          before do
            allow(policy_result).to receive(:error).and_return(validation_error)
          end
  
          it 'reports an error' do
            result = subject.report(policy_result)
            expect(result).to be_a(Hash)
            expect(result).to include(:errors, :status)
            expect(result[:errors].length).to eq(1)
            expect(result[:status]).to eq("Invalid YAML")
          end
        end
  
        context 'and the policy result is valid' do
          let(:validation_error) { nil }
  
          before do
            allow(policy_result).to receive(:error).and_return(validation_error)
          end
  
          it 'reports successfully' do
            result = subject.report(policy_result)
            expect(result).to be_a(Hash)
            expect(result).to include(:created, :deleted, :updated)
            expect(result[:status]).to eq("Valid YAML")
            expect(result[:created][:items].length).to eq(0)
            expect(result[:deleted][:items].length).to eq(0)
            expect(result[:updated][:before][:items].length).to eq(0)
            expect(result[:updated][:after][:items].length).to eq(0)      
          end
        end
      end
    end
  end

  describe '#authorize' do
    let(:subject) { Loader::ReplacePolicy }
    let(:current_user) { instance_double('User') }
    let(:resource) { instance_double('Resource', resource_id: 'rspec:resource:some_resource') }
    let(:logger) { double("Rails.logger") }

    context 'when the current user is not authorized' do
      before do
        allow(current_user).to receive(:policy_permissions?).with(resource, 'update').and_return(false)
        allow(current_user).to receive(:role_id).and_return("rspec:user:alice")
      end

      it 'logs an unauthorized access attempt and raises Forbidden' do
        expect(logger).to receive(:info).with(
          instance_of(Errors::Authentication::Security::RoleNotAuthorizedOnPolicyDescendants)
        )
        expect do 
          subject.authorize(
            current_user,
            resource,
            logger: logger
          )
        end.to raise_error(ApplicationController::Forbidden)
      end
    end
    context 'when the current user is authorized' do
      before do
        allow(current_user).to receive(:policy_permissions?).with(resource, 'update').and_return(true)
      end

      it 'does not raise an error' do
        expect do 
          subject.authorize(
            current_user,
            resource,
            logger: logger
          )
        end.not_to raise_error
      end
    end
  end
end
