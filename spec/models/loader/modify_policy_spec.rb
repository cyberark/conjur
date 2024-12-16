# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Loader::ModifyPolicy) do
  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }
  # When a Loader is called, a PolicyResult is returned.
  let(:policy_result) { ::PolicyResult }
  let(:policy_version) { nil }
  let(:logger) { Rails.logger }

  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')
  end

  let(:subject) do
    Loader::ModifyPolicy.from_policy(
      policy_parse,
      policy_version,
      policy_loader_class,
      current_user,
      policy_result: policy_result,
      logger: logger
    )
  end

  let(:policy_parse) do
    PolicyParse.new([], nil)
  end

  let(:mock_records) do
    {
      annotations: annotations,
      credentials: credentials,
      permissions: permissions,
      resources: resources,
      role_memberships: role_memberships,
      roles: roles
    }
  end

  let(:dryrun) do
    true
  end

  let(:base) do
    Loader::Orchestrate.new(
      dryrun: dryrun,
      policy_diff: policy_diff,
      policy_parse: policy_parse,
      policy_version: policy_version,
      logger: logger
    ).tap do |loader|
      # These methods are called during the policy loading procedures.
      allow(loader).to receive(:setup_db_for_new_policy).and_return(nil)
      allow(loader).to receive(:delete_shadowed_and_duplicate_rows).and_return(nil)
      allow(loader).to receive(:upsert_policy_records).and_return(nil)
      allow(loader).to receive(:clean_db).and_return(nil)
      allow(loader).to receive(:release_db_connection).and_return(nil)

      # Diff specific methods
      allow(loader).to receive(:store_policy_in_db).and_return(credentials)
      allow(loader).to receive(:store_auxiliary_data).and_return(credentials)
      allow(loader).to receive(:fetch_created_rows).and_return(mock_records)
      allow(loader).to receive(:fetch_original_resources).and_return(mock_records)
      allow(loader).to receive(:dryrun_clean_db).and_return(mock_records)
      allow(loader).to receive(:filter_unique_records).and_return([])
      allow(loader).to receive(:create_diff).and_return(policy_diff_response)
      
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

  let(:policy_loader) do
    Loader::DryRun.new(
      policy_parse: policy_parse,
      policy_version: policy_version,
      base: base,
      logger: logger
    ).tap do |loader|
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
    {
      created: diff_response,
      deleted: diff_response,
      updated: diff_response,
      final: diff_response
    }
  end

  let(:policy_diff) do
    CommandHandler::PolicyDiff.new.tap do |mock|
      allow(mock).to receive(:call)
        .and_return(policy_diff_response)
    end
  end

  describe '.call' do
    context 'when a policy is loaded with dryrun' do 
      context 'when dryrun is false' do
        let(:dryrun) { false }

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

        context 'when the diff query contains only credentials' do
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
            diff: diff_response,
            visible_resources_before: { some_key: 'some_value' },
            visible_resources_after: { some_key: 'some_value' }
          )
        end
  
        before do
          allow(mock_policy_result_input).to receive(:created_roles=).and_return(nil)
          allow(mock_policy_result_input).to receive(:diff=).and_return(nil)
          allow(mock_policy_result_input).to receive(:visible_resources_before=).and_return(nil)
          allow(mock_policy_result_input).to receive(:visible_resources_after=).and_return(nil)
        end
  
        it 'receives .call and assigns created_roles and diff' do
          expect(subject).to receive(:call).and_return(mock_policy_result_output)
          expect(mock_policy_result_input).to receive(:created_roles=).with(%w[role1 role2])
          expect(mock_policy_result_input).to receive(:diff=).with(diff_response)
          expect(mock_policy_result_input).to receive(:visible_resources_before=).with(hash_including(:some_key))
          expect(mock_policy_result_input).to receive(:visible_resources_after=).with(hash_including(:some_key))
  
          subject.call_pr(mock_policy_result_input)
        end
      end
    end
  end
end
