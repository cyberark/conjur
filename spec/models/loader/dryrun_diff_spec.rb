# frozen_string_literal: true

require 'spec_helper'
require 'spec_helper_policy'

# Borrowed from spec/models/loader/validate_spec.rb
# rubocop:disable Layout/ClosingHeredocIndentation
# rubocop:disable Layout/CommentIndentation

describe Loader::DryRun do
  before(:all) do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
    Role.find_or_create(role_id: 'rspec:user:admin')
  end

  def find_or_create_root_policy(account)
    Loader::Types.find_or_create_root_policy(account)
  end

  def parse_policy(resource:, policy:, policy_result:)
    parse = Commands::Policy::Parse.new.call(
      account: resource.account,
      policy_id: resource.identifier,
      owner_id: resource.owner.id,
      root_policy: resource.kind == "policy" && resource.identifier == "root",
      policy_filename: nil,
      policy_text: policy
    )
    policy_result.policy_parse = (parse)
  end

  # The point of this large function is to be able to perform a policy diff
  # that returns the diff result directly so that it can be tested against
  # expectations.  This gets into the DryRun class without the need to rely
  # on an API response.

  def raw_diff_wrapper(
    policy_result:,
    test_policy:,
    test_loader:,
    test_delete_permitted:,
    test_account:,
    test_user:,
    test_ip:,
    apply_policy: false
  )

    test_resource = Loader::Types.find_or_create_root_policy(test_account)
    test_loader.authorize(test_user, test_resource)

    # ----- 1st pass: Validation -----

    parse_policy(
      resource: test_resource,
      policy: test_policy,
      policy_result: policy_result
    )

    loader = test_loader.from_policy(
      policy_result.policy_parse,
      nil,
      Loader::Validate
    )
    loader.call_pr(policy_result)

    # ----- 2nd pass: DryRun -----

    # Sequel::Model.db.transaction(savepoint: true) do
    version = PolicyVersion.new(
      role: test_user,
      policy: test_resource,
      policy_text: test_policy,
      client_ip: test_ip,
      policy_parse: policy_result.policy_parse
    )
    version.delete_permitted = test_delete_permitted
    version.save
    policy_result.policy_version = (version)

    loader = test_loader.from_policy(
      policy_result.policy_parse,
      policy_result.policy_version,
      apply_policy ? Loader::Orchestrate : Loader::DryRun
    )
    loader.call_pr(policy_result)
  end

  # ----------------------------------------------------- #

  # Test case defaults:

  test_account = 'rspec' # or cucumber when running via CLI API
  test_user = 'admin'
  test_ip = '0.0.0.0'

  # authorize in same manner used by root_loader

  user_id = "#{test_account}:user:#{test_user}"
  user_role = ::Role[user_id] || ::Role.create(role_id: user_id)
  test_current_user = user_role

  # ----------------------------------------------------- #

  # Policies

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

  # it verifies against the Simple Examples: Raw Diff -- Roles'

  # from SD, "Simple Examples: Raw Diff, Mapper, DTOs":

  # empty policy, differences will all be created
  base_simple_example =
    <<~POLICY
      #
           POLICY

  # dry-run-policies/00-empty.yml
  diff_simple_example =
    <<~POLICY
      - !policy
        id: example
        body:
          - !user
            id: barrett
            restricted_to: [ "127.0.0.1" ]
            annotations:
              key: value
          - !variable
            id: secret01
            annotations:
              key: value
          - !permit
            role: !user barrett
            privileges: [ read, execute ]
            resources:
              - !variable secret01
           POLICY

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

  # it verifies against the Complex Examples: Raw Diff -- Resources

  # dry-run-policies/00-empty.yml
  base_complex_example =
    <<~POLICY
      #
           POLICY

  # from SD, "Complex Examples: Raw Diff, Mapper, DTOs"

  diff_complex_example =
      # from SD, "Complex Examples: Raw Diff, Mapper, DTOs"
    dryrun_test_policy =
      <<~POLICY
        - !policy
          id: example
          body:
            - !user
              id: alice
              annotations:
                key: value
            - !user
              id: annie
              annotations:
                key: value
            - !user
              id: bob
              annotations:
                key: value
            - !user
              id: barrett
              restricted_to: [ "127.0.0.1" ]
              annotations:
                key: value
            - !user
              id: carson
              annotations:
                key: value
            - !policy
              id: alpha
              owner: !user alice
              body:
                - &alpha_variables
                  - !variable
                    id: secret01
                    annotations:
                      key: value
                  - !variable
                    id: secret02
                    annotations:
                      key: value
                - !group
                  id: secret-users
                  annotations:
                    key: value
                - !grant
                  role: !group secret-users
                  member: !user /example/annie
                - !permit
                  role: !group secret-users
                  privileges: [ read, execute ]
                  resources: *alpha_variables
            - !policy
              id: omega
              owner: !user bob
              body:
                - &omega_variables
                  - !variable
                    id: secret01
                    annotations:
                      key: value
                  - !variable
                    id: secret02
                    annotations:
                      key: value
                - !group
                  id: secret-users
                  annotations:
                    key: value
                - !grant
                  role: !group secret-users
                  member: !user /example/barrett
                - !permit
                  role: !group secret-users
                  privileges: [ read, execute ]
                  resources: *omega_variables
           POLICY

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

  # it verifies diff resulting from Update Role Memberships

  base_update_role_memberships =
    <<~POLICY
      - !policy
        id: foo-bar
        body:
        - !user
          id: alice
          annotations:
            alpha: the first letter of the Greek alphabet
          restricted_to: [ "127.0.0.1", "10.0.0.0/24" ]
        - &variables
          - !variable
            id: secret01
            annotations:
              alpha: the first letter of the Greek alphabet
        - !group
          id: secret-users
          annotations:
            alpha: the first letter of the Greek alphabet
        - !grant
          role: !group secret-users
          members:
          - !user alice
        - !permit
          role: !group secret-users
          privileges: [ read, execute ]
          resources: *variables
           POLICY

  # PATCH root "policies/dry-run-policies/examples/update/input/01.02-update_role_memberships.yml"
  diff_update_role_memberships =
    <<~POLICY
      - !policy
        id: foo-bar
        body:
        - !revoke
          role: !group secret-users
          member: !user alice
           POLICY

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

  # it verifies diff resulting from Update to Delete Role

  # PUT "policies/dry-run-policies/examples/update/input/00-base.yml"
  base_update_delete_role =
    <<~POLICY
      - !policy
        id: foo-bar
        body:
        - !user
          id: alice
          annotations:
            description: I made Bob the fall guy
        - !user
          id: bob
          annotations:
            alpha: the first letter of the Greek alphabet
          restricted_to: [ "127.0.0.1", "10.0.0.0/24" ]
        - &variables
          - !variable
            id: secret01
            annotations:
              alpha: the first letter of the Greek alphabet
        - !group
          id: secret-users
          annotations:
            alpha: the first letter of the Greek alphabet
        - !grant
          role: !group secret-users
          members:
          - !user alice
        - !permit
          role: !group secret-users
          privileges: [ read, execute ]
          resources: *variables
           POLICY

  # PATCH "policies/dry-run-policies/examples/update/input/01.03-delete_role.yml"
  diff_update_delete_role =
    <<~POLICY
      - !policy
        id: foo-bar
        body:
        - !delete
          record: !user bob
           POLICY

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

  # it verifies diff resulting from Replace policy operations

  # dry-run-policies/examples/replace/input/00-base.yml
  base_replace_policy =
    <<~POLICY
      - !policy
        id: foo-bar
        body:
        - !user
          id: alice
          annotations:
            alpha: the first letter of the Greek alphabet
          restricted_to: [ "127.0.0.1", "10.0.0.0/24" ]
        - &variables
          - !variable
            id: secret01
            annotations:
      
              alpha: the first letter of the Greek alphabet
        - !group
          id: secret-users
          annotations:
            alpha: the first letter of the Greek alphabet
        - !grant
          role: !group secret-users
          members:
          - !user alice
        - !permit
          role: !group secret-users
          privileges: [ read, execute ]
          resources: *variables
           POLICY

  # dry-run-policies/examples/replace/raw_diff/01.01-existing_roles_and_groups.json
  diff_replace_policy =
    <<~POLICY
      - !policy
        id: foo-bar
        body:
        - !user
          id: bob
          annotations:
            alpha: the first letter of the Greek alphabet
          restricted_to: [ "127.0.0.1", "10.0.0.0/24" ]
        - &variables
          - !variable
            id: secret01
            annotations:
              alpha: the first letter of the Greek alphabet
        - !group
          id: secret-users
          annotations:
            alpha: the first letter of the Greek alphabet
        - !grant
          role: !group secret-users
          members:
          - !user bob
        - !permit
          role: !group secret-users
          privileges: [ read, execute ]
          resources: *variables
           POLICY

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

  # it verifies diff with no created items and all types of deleted items

  # dry-run-policies/update-01.yml
  base_delete_all =
    <<~POLICY
      - !policy
        id: foo-bar
        body:
        - !user
          id: alice
          annotations:
            alpha: the first letter of the Greek alphabet
          restricted_to: [ "127.0.0.1", "10.0.0.0/24" ]
        - &variables
          - !variable
            id: secret01
            annotations:
              alpha: the first letter of the Greek alphabet
        - !group
          id: secret-users
          annotations:
            alpha: the first letter of the Greek alphabet
        - !grant
          role: !group secret-users
          members:
          - !user alice
        - !permit
          role: !group secret-users
          privileges: [ read, execute ]
          resources: *variables
           POLICY

  # dry-run-policies/update-03.yml
  diff_delete_all =
    <<~POLICY
      - !policy
        id: foo-bar
        body:
        - !revoke
          role: !group secret-users
          member: !user bob
           POLICY

  # ----------------------------------------------------- #

  context "when using test cases from the Policy DryRun Solution Design" do
    # Each "it" example uses 2 policies to set up a testable diff.

    # ----------------------------------------------------- #

    it 'it verifies against the Simple Examples: Raw Diff -- Roles' do
      base_test_policy = base_simple_example

      policy_result = PolicyResult.new

      raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: base_test_policy,
        test_loader: Loader::ReplacePolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip,
        apply_policy: true
      )
      # Confirm that it was not rejected
      expect(policy_result.error).to be(nil)

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

      dryrun_test_policy = diff_simple_example

      policy_result = PolicyResult.new

      response = raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: dryrun_test_policy,
        test_loader: Loader::CreatePolicy,
        test_delete_permitted: false,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip
      )

      expect(response).to_not be(nil)
      expect(policy_result.error).to be(nil)

      # Spot checks...
      diff = policy_result.diff
      expect(diff[:created].annotations.length).to be == 2
      expect(diff[:created].permissions.length).to be == 2
      expect(diff[:created].resources.length).to be == 3
      expect(diff[:created].role_memberships.length).to be == 2
      expect(diff[:created].roles.length).to be == 2
      expect(diff[:created].credentials.length).to be == 1

      expect(diff[:deleted].annotations.length).to be == 0
      expect(diff[:deleted].permissions.length).to be == 0
      expect(diff[:deleted].resources.length).to be == 0
      expect(diff[:deleted].role_memberships.length).to be == 0
      expect(diff[:deleted].roles.length).to be == 0
      expect(diff[:deleted].credentials.length).to be == 0
    end

    # ----------------------------------------------------- #

    it 'it verifies against the Complex Examples: Raw Diff -- Resources' do
      base_test_policy = base_complex_example

      policy_result = PolicyResult.new

      response = raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: base_test_policy,
        test_loader: Loader::CreatePolicy,
        test_delete_permitted: false,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip
      )

      expect(response).to_not be(nil)
      expect(policy_result.error).to be(nil)

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

      dryrun_test_policy = diff_complex_example

      policy_result = PolicyResult.new

      response = raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: dryrun_test_policy,
        test_loader: Loader::CreatePolicy,
        test_delete_permitted: false,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip
      )

      expect(response).to_not be(nil)
      expect(policy_result.error).to be(nil)

      # Spot checks...
      diff = policy_result.diff

      # Number of elements...
      expect(diff[:created].annotations.length).to be == 11
      expect(diff[:created].permissions.length).to be == 8
      expect(diff[:created].resources.length).to be == 14
      expect(diff[:created].role_memberships.length).to be == 12
      expect(diff[:created].roles.length).to be == 10
      expect(diff[:created].credentials.length).to be == 1

      expect(diff[:deleted].annotations.length).to be == 0
      expect(diff[:deleted].permissions.length).to be == 0
      expect(diff[:deleted].resources.length).to be == 0
      expect(diff[:deleted].role_memberships.length).to be == 0
      expect(diff[:deleted].roles.length).to be == 0
      expect(diff[:deleted].credentials.length).to be == 0

      expect(diff[:updated].annotations.length).to be == 0
      expect(diff[:updated].permissions.length).to be == 0
      expect(diff[:updated].resources.length).to be == 0
      expect(diff[:updated].role_memberships.length).to be == 1
      expect(diff[:updated].roles.length).to be == 1
      expect(diff[:updated].credentials.length).to be == 0
    end

    # ----------------------------------------------------- #

    it 'it verifies diff resulting from Update Role Memberships' do
      base_test_policy = base_update_role_memberships

      policy_result = PolicyResult.new

      raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: base_test_policy,
        test_loader: Loader::CreatePolicy,
        test_delete_permitted: false,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip,
        apply_policy: true
      )

      expect(policy_result.error).to be(nil)

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

      # PATCH root "policies/dry-run-policies/examples/update/input/01.02-update_role_memberships.yml"
      dryrun_test_policy = diff_update_role_memberships

      policy_result = PolicyResult.new

      response = raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: dryrun_test_policy,
        test_loader: Loader::ModifyPolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip
      )

      expect(response).to_not be(nil)
      expect(policy_result.error).to be(nil)

      diff = policy_result.diff

      expect(diff[:created].annotations.length).to be == 0
      expect(diff[:created].permissions.length).to be == 0
      expect(diff[:created].resources.length).to be == 0
      expect(diff[:created].role_memberships.length).to be == 0
      expect(diff[:created].roles.length).to be == 0
      expect(diff[:created].credentials.length).to be == 0

      expect(diff[:deleted].annotations.length).to be == 0
      expect(diff[:deleted].permissions.length).to be == 0
      expect(diff[:deleted].resources.length).to be == 0

      expect(diff[:deleted].role_memberships.length).to be == 1

      expect(diff[:deleted].roles.length).to be == 0
      expect(diff[:deleted].credentials.length).to be == 0
      expect(diff[:deleted].role_memberships[0][:role_id]).to match("rspec:group:foo-bar/secret-users")

      expect(diff[:updated].annotations.length).to be == 2
      expect(diff[:updated].permissions.length).to be == 2
      expect(diff[:updated].resources.length).to be == 2
      expect(diff[:updated].role_memberships.length).to be == 3
      expect(diff[:updated].roles.length).to be == 2
      expect(diff[:updated].credentials.length).to be == 1
    end

    # ----------------------------------------------------- #

    it 'it verifies diff resulting from Update to Delete Role' do
      # PUT "policies/dry-run-policies/examples/update/input/00-base.yml"
      # Note: a version of this policy made alice the default user and then
      #   deleted bob in the dryrun policy, with no net effect.
      #   An update this policy adds user bob so that there are results to
      #   verify when he is deleted.
      base_test_policy = base_update_delete_role

      policy_result = PolicyResult.new

      raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: base_test_policy,
        test_loader: Loader::ReplacePolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip,
        apply_policy: true
      )

      expect(policy_result.error).to be(nil)

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

      dryrun_test_policy = diff_update_delete_role

      policy_result = PolicyResult.new

      response = raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: dryrun_test_policy,
        test_loader: Loader::ModifyPolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip
      )

      expect(response).to_not be(nil)
      expect(policy_result.error).to be(nil)

      diff = policy_result.diff

      expect(diff[:created].annotations.length).to be == 0
      expect(diff[:created].permissions.length).to be == 0
      expect(diff[:created].resources.length).to be == 0
      expect(diff[:created].role_memberships.length).to be == 0
      expect(diff[:created].roles.length).to be == 0
      expect(diff[:created].credentials.length).to be == 0

      expect(diff[:deleted].annotations.length).to be == 1
      expect(diff[:deleted].permissions.length).to be == 0
      expect(diff[:deleted].resources.length).to be == 1
      expect(diff[:deleted].role_memberships.length).to be == 1
      expect(diff[:deleted].roles.length).to be == 1
      expect(diff[:deleted].credentials.length).to be == 1

      expect(diff[:updated].annotations.length).to be == 1
      expect(diff[:updated].permissions.length).to be == 0
      expect(diff[:updated].resources.length).to be == 1
      expect(diff[:updated].role_memberships.length).to be == 4
      expect(diff[:updated].roles.length).to be == 2
      expect(diff[:updated].credentials.length).to be == 1

      expect(diff[:deleted].annotations[0][:resource_id]).to match("rspec:user:bob@foo-bar")
      expect(diff[:deleted].annotations[0][:name]).to match("alpha")
      expect(diff[:deleted].resources[0][:resource_id]).to match("rspec:user:bob@foo-bar")
      expect(diff[:deleted].resources[0][:owner_id]).to match("rspec:policy:foo-bar")

      expect(diff[:deleted].role_memberships[0][:role_id]).to match("rspec:user:bob@foo-bar")
      expect(diff[:deleted].role_memberships[0][:member_id]).to match("rspec:policy:foo-bar")
      expect(diff[:deleted].role_memberships[0][:admin_option]).to be(true)
      expect(diff[:deleted].role_memberships[0][:ownership]).to be(true)
      expect(diff[:deleted].role_memberships[0][:policy_id]).to match("rspec:policy:root")
      expect(diff[:deleted].roles[0][:role_id]).to match("rspec:user:bob@foo-bar")
      expect(diff[:deleted].roles[0][:policy_id]).to match("rspec:policy:root")
      expect(diff[:deleted].credentials[0][:role_id]).to match("rspec:user:bob@foo-bar")
    end

    # ----------------------------------------------------- #

    it 'it verifies diff resulting from Replace policy operations' do
      # dry-run-policies/examples/replace/input/00-base.yml
      base_test_policy = base_replace_policy

      policy_result = PolicyResult.new

      raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: base_test_policy,
        test_loader: Loader::ReplacePolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip,
        apply_policy: true
      )

      expect(policy_result.error).to be(nil)

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

      # dry-run-policies/examples/replace/input/01.01-existing_roles_and_groups.yml"
      dryrun_test_policy = diff_replace_policy

      policy_result = PolicyResult.new

      response = raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: dryrun_test_policy,
        test_loader: Loader::ReplacePolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip
      )

      expect(response).to_not be(nil)
      expect(policy_result.error).to be(nil)

      # Detailed verification, relying on this result for reference:
      #   dry-run-policies/examples/replace/raw_diff/01.01-existing_roles_and_groups.json
      diff = policy_result.diff

      # Check number of elements produced:
      expect(diff[:created].annotations.length).to be == 1
      expect(diff[:created].permissions.length).to be == 0
      expect(diff[:created].resources.length).to be == 1
      expect(diff[:created].role_memberships.length).to be == 2
      expect(diff[:created].roles.length).to be == 1
      expect(diff[:created].credentials.length).to be == 1

      expect(diff[:deleted].annotations.length).to be == 1
      expect(diff[:deleted].permissions.length).to be == 0
      expect(diff[:deleted].resources.length).to be == 1
      expect(diff[:deleted].role_memberships.length).to be == 2
      expect(diff[:deleted].roles.length).to be == 1
      expect(diff[:deleted].credentials.length).to be == 1

      expect(diff[:updated].annotations.length).to be == 2
      expect(diff[:updated].permissions.length).to be == 2
      expect(diff[:updated].resources.length).to be == 2
      expect(diff[:updated].role_memberships.length).to be == 4
      expect(diff[:updated].roles.length).to be == 3
      expect(diff[:updated].credentials.length).to be == 1

      # Verify some content of the replaced elements:
      # (there's only one element in each set so we can reference it at known index)
      expect(diff[:deleted].annotations[0][:resource_id]).to match("rspec:user:alice@foo-bar")
      expect(diff[:created].annotations[0][:resource_id]).to match("rspec:user:bob@foo-bar")
      expect(diff[:deleted].resources[0][:resource_id]).to match("rspec:user:alice@foo-bar")
      expect(diff[:created].resources[0][:resource_id]).to match("rspec:user:bob@foo-bar")
      expect(diff[:deleted].roles[0][:role_id]).to match("rspec:user:alice@foo-bar")
      expect(diff[:created].roles[0][:role_id]).to match("rspec:user:bob@foo-bar")

      expect(diff[:deleted].credentials[0][:role_id]).to match("rspec:user:alice@foo-bar")
      expect(diff[:created].credentials[0][:role_id]).to match("rspec:user:bob@foo-bar")
    end

    # ----------------------------------------------------- #

    it 'it verifies diff with no created items and all types of deleted items' do
      # dry-run-policies/update-01.yml
      base_test_policy = base_delete_all

      policy_result = PolicyResult.new

      raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: base_test_policy,
        test_loader: Loader::ReplacePolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip,
        apply_policy: true
      )

      expect(policy_result.error).to be(nil)

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

      # dry-run-policies/update-03.yml
      dryrun_test_policy = diff_delete_all

      policy_result = PolicyResult.new

      response = raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: dryrun_test_policy,
        test_loader: Loader::ReplacePolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip
      )

      expect(response).to_not be(nil)
      expect(policy_result.error).to be(nil)

      # Detailed verification,
      # all created should be empty, all deleted list items
      diff = policy_result.diff

      expect(diff[:created].annotations.length).to be == 0
      expect(diff[:created].permissions.length).to be == 0
      expect(diff[:created].resources.length).to be == 0
      expect(diff[:created].role_memberships.length).to be == 0
      expect(diff[:created].roles.length).to be == 0
      expect(diff[:created].credentials.length).to be == 0

      expect(diff[:deleted].annotations.length).to be == 3
      expect(diff[:deleted].permissions.length).to be == 2
      expect(diff[:deleted].resources.length).to be == 3
      expect(diff[:deleted].role_memberships.length).to be == 3
      expect(diff[:deleted].roles.length).to be == 2
      expect(diff[:deleted].credentials.length).to be == 1

      expect(diff[:updated].annotations.length).to be == 3
      expect(diff[:updated].permissions.length).to be == 2
      expect(diff[:updated].resources.length).to be == 1
      expect(diff[:updated].role_memberships.length).to be == 4
      expect(diff[:updated].roles.length).to be == 3
      expect(diff[:updated].credentials.length).to be == 1
    end

    # ----------------------------------------------------- #

    it 'it verifies diff with no net change in policy' do
      # policy that creates all types
      base_test_policy = diff_complex_example

      policy_result = PolicyResult.new

      raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: base_test_policy,
        test_loader: Loader::ReplacePolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip,
        apply_policy: true
      )

      expect(policy_result.error).to be(nil)

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - #

      # same policy -- no net change expected
      dryrun_test_policy = diff_complex_example

      policy_result = PolicyResult.new

      response = raw_diff_wrapper(
        policy_result: policy_result,
        test_policy: dryrun_test_policy,
        test_loader: Loader::ReplacePolicy,
        test_delete_permitted: true,
        test_account: test_account,
        test_user: test_current_user,
        test_ip: test_ip
      )

      expect(response).to_not be(nil)
      expect(policy_result.error).to be(nil)

      # Detailed verification,
      # all created should be empty, all deleted list items
      diff = policy_result.diff

      expect(diff[:created].annotations.length).to be == 0
      expect(diff[:created].permissions.length).to be == 0
      expect(diff[:created].resources.length).to be == 0
      expect(diff[:created].role_memberships.length).to be == 0
      expect(diff[:created].roles.length).to be == 0
      expect(diff[:created].credentials.length).to be == 0

      expect(diff[:deleted].annotations.length).to be == 0
      expect(diff[:deleted].permissions.length).to be == 0
      expect(diff[:deleted].resources.length).to be == 0
      expect(diff[:deleted].role_memberships.length).to be == 0
      expect(diff[:deleted].roles.length).to be == 0
      expect(diff[:deleted].credentials.length).to be == 0

      expect(diff[:updated].annotations.length).to be == 0
      expect(diff[:updated].permissions.length).to be == 0
      expect(diff[:updated].resources.length).to be == 0
      expect(diff[:updated].role_memberships.length).to be == 0
      expect(diff[:updated].roles.length).to be == 0
      expect(diff[:updated].credentials.length).to be == 0
    end

    # ----------------------------------------------------- #
  end
end
