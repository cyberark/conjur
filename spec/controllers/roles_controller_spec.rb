# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

NONEXISTING_GROUP_URL = '/roles/rspec/group/none'
UNPERMITTED_HOST_ID = 'rspec:host:none'
ADMIN_HOST_ID = 'rspec:user:admin'
ADMIN_HOST_URL = '/roles/rspec/user/admin'

describe RolesController, type: :request do
  before do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new

    # Load the test policy into Conjur
    put(
      '/policies/rspec/policy/root',
      env: token_auth_header(role: admin_user).merge(
        { 'RAW_POST_DATA' => test_policy }
      )
    )
    assert_response :success
  end

  # The test policy consists of four Groups in a topology that allows us to
  # test various scenarios around retrieving the members and memberships for
  # a given Role.
  let(:test_policy) do
    <<~POLICY
    - !group a
    - !group b
    - !group c
    - !group d

    - !grant
      role: !group a
      members:
        - !group b
        - !group c

    - !grant
      role: !group c
      member: !group d

    - !host none
    - !host a
    - !host c
    - !host d

    - !permit
      resource: !group a
      role: !host a
      privileges: [ read ]

    - !permit
      resource: !group c
      role: !host c
      privileges: [ read ]

    - !permit
      resource: !group d
      role: !host d
      privileges: [ read ]
    POLICY
  end

  let(:admin_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  let(:current_user) { Role.find_or_create(role_id: current_user_id) }
  let(:current_user_id) { 'rspec:user:admin' }

  let(:role_url) { '/roles/rspec/group/test' }

  describe '#show' do
    # Test cases to verify a role that doesn't exist, a role the current user
    # doesn't have read privilege on, and a role that the current user does have
    # read privilege on.
    [
      {
        user_id: ADMIN_HOST_ID,
        role_url: ADMIN_HOST_URL,
        expected_response: :not_found
      },
      {
        user_id: UNPERMITTED_HOST_ID,
        role_url: '/roles/rspec/group/a',
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:a',
        role_url: NONEXISTING_GROUP_URL,
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:a',
        role_url: '/roles/rspec/group/a',
        expected_response: :success
      },
    ].each do |test_case|
      context "when the user is '#{test_case[:user_id]}' accessing '#{test_case[:role_url]}'" do
        let(:role_url) { test_case[:role_url] }
        let(:current_user_id) { test_case[:user_id] }

        it "returns '#{test_case[:expected_response]}'" do
          get(
            "#{test_case[:role_url]}",
            env: token_auth_header(role: current_user)
          )
          assert_response test_case[:expected_response]
        end
      end
    end
  end

  describe '#all_memberships' do
    # Test cases
    [
      {
        user_id: ADMIN_HOST_ID,
        role_url: ADMIN_HOST_URL,
        expected_response: :not_found
      },
      {
        user_id: UNPERMITTED_HOST_ID,
        role_url: '/roles/rspec/group/d',
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:d',
        role_url: NONEXISTING_GROUP_URL,
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:d',
        role_url: '/roles/rspec/group/d',
        expected_response: :success
      },
    ].each do |test_case|
      context "when the user is '#{test_case[:user_id]}' accessing '#{test_case[:role_url]}'" do
        let(:role_url) { test_case[:role_url] }
        let(:current_user_id) { test_case[:user_id] }

        it "returns '#{test_case[:expected_response]}'" do
          get(
            "#{test_case[:role_url]}?all",
            env: token_auth_header(role: current_user)
          )
          assert_response test_case[:expected_response]
        end
      end
    end
  end

  describe '#direct_memberships' do
    # Test cases
    [
      {
        user_id: ADMIN_HOST_ID,
        role_url: ADMIN_HOST_URL,
        expected_response: :not_found
      },
      {
        user_id: UNPERMITTED_HOST_ID,
        role_url: '/roles/rspec/group/d',
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:d',
        role_url: NONEXISTING_GROUP_URL,
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:d',
        role_url: '/roles/rspec/group/d',
        expected_response: :success
      },
    ].each do |test_case|
      context "when the user is '#{test_case[:user_id]}' accessing '#{test_case[:role_url]}'" do
        let(:role_url) { test_case[:role_url] }
        let(:current_user_id) { test_case[:user_id] }

        it "returns '#{test_case[:expected_response]}'" do
          get(
            "#{test_case[:role_url]}?memberships",
            env: token_auth_header(role: current_user)
          )
          assert_response test_case[:expected_response]
        end
      end
    end
  end

  describe '#members' do
    # Test cases
    [
      {
        user_id: ADMIN_HOST_ID,
        role_url: ADMIN_HOST_URL,
        expected_response: :not_found
      },
      {
        user_id: UNPERMITTED_HOST_ID,
        role_url: '/roles/rspec/group/a',
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:a',
        role_url: NONEXISTING_GROUP_URL,
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:a',
        role_url: '/roles/rspec/group/a',
        expected_response: :success
      },
    ].each do |test_case|
      context "when the user is '#{test_case[:user_id]}' accessing '#{test_case[:role_url]}'" do
        let(:role_url) { test_case[:role_url] }
        let(:current_user_id) { test_case[:user_id] }

        it "returns '#{test_case[:expected_response]}'" do
          get(
            "#{test_case[:role_url]}?members",
            env: token_auth_header(role: current_user)
          )
          assert_response test_case[:expected_response]
        end
      end
    end
  end

  describe '#graph' do
    # Test cases
    [
      {
        user_id: ADMIN_HOST_ID,
        role_url: ADMIN_HOST_URL,
        expected_response: :not_found
      },
      {
        user_id: UNPERMITTED_HOST_ID,
        role_url: '/roles/rspec/group/c',
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:c',
        role_url: NONEXISTING_GROUP_URL,
        expected_response: :not_found
      },
      {
        user_id: 'rspec:host:c',
        role_url: '/roles/rspec/group/c',
        expected_response: :success
      },
    ].each do |test_case|
      context "when the user is '#{test_case[:user_id]}' accessing '#{test_case[:role_url]}'" do
        let(:role_url) { test_case[:role_url] }
        let(:current_user_id) { test_case[:user_id] }

        it "returns '#{test_case[:expected_response]}'" do
          get(
            "#{test_case[:role_url]}?graph",
            env: token_auth_header(role: current_user)
          )
          assert_response test_case[:expected_response]
        end
      end
    end
  end

  describe '#add_member' do
    before(:each) do
      payload = <<~YAML
        - !group test
        - !group other
      YAML

      put(
        '/policies/rspec/policy/root',
        env: token_auth_header(role: current_user).merge({ 'RAW_POST_DATA' => payload })
      )
    end

    context 'when the role API extensions are enabled' do
      let(:extension_double) do
        instance_double(Conjur::Extension::Extension)
          .tap do |extension_double|
            allow(extension_double)
              .to receive(:call)
          end
      end

      before do
        allow_any_instance_of(Conjur::FeatureFlags::Features)
          .to receive(:enabled?).with(:roles_api_extensions).and_return(true)

        allow_any_instance_of(Conjur::Extension::Repository)
          .to receive(:extension)
          .with(kind: RolesController::ROLES_API_EXTENSION_KIND)
          .and_return(extension_double)
      end

      it "loads the extension classes" do
        expect_any_instance_of(Conjur::Extension::Repository)
          .to receive(:extension)
          .with(kind: RolesController::ROLES_API_EXTENSION_KIND)

        post(
          "#{role_url}?members&member=rspec:group:other",
          env: token_auth_header(role: current_user)
        )
      end

      it "emits the expected callbacks" do
        expect(extension_double)
          .to receive(:call)
          .with(:before_add_member, role: anything, member: anything)

        expect(extension_double)
          .to receive(:call)
          .with(:after_add_member, role: anything, member: anything, membership: anything)

        post(
          "#{role_url}?members&member=rspec:group:other",
          env: token_auth_header(role: current_user)
        )
      end
    end

    context 'when the role API extensions are disabled' do
      before do
        allow_any_instance_of(Conjur::FeatureFlags::Features)
          .to receive(:enabled?).with(:roles_api_extensions).and_return(false)
      end

      it "does not load the extension classes" do
        expect_any_instance_of(Conjur::Extension::Repository)
          .not_to receive(:extension_set)
          .with(RolesController::ROLES_API_EXTENSION_KIND)

        post(
          "#{role_url}?members&member=rspec:group:other",
          env: token_auth_header(role: current_user)
        )
      end
    end
  end

  describe '#delete_member' do
    before(:each) do
      payload = <<~YAML
        - !group test
        - !group other

        - !grant
          role: !group test
          member: !group other
      YAML

      put(
        '/policies/rspec/policy/root',
        env: token_auth_header(role: current_user).merge({ 'RAW_POST_DATA' => payload })
      )
    end

    context 'when the role API extensions are enabled' do
      let(:extension_double) do
        instance_double(Conjur::Extension::Extension)
          .tap do |extension_double|
            allow(extension_double)
              .to receive(:call)
          end
      end

      before do
        allow_any_instance_of(Conjur::FeatureFlags::Features)
          .to receive(:enabled?).with(:roles_api_extensions).and_return(true)

        allow_any_instance_of(Conjur::Extension::Repository)
          .to receive(:extension)
          .with(kind: RolesController::ROLES_API_EXTENSION_KIND)
          .and_return(extension_double)
      end

      it "loads the extension classes" do
        expect_any_instance_of(Conjur::Extension::Repository)
          .to receive(:extension)
          .with(kind: RolesController::ROLES_API_EXTENSION_KIND)

        delete(
          "#{role_url}?members&member=rspec:group:other",
          env: token_auth_header(role: current_user)
        )
      end

      it "runs the expected callbacks" do
        expect(extension_double)
          .to receive(:call)
          .with(:before_delete_member, role: anything, member: anything, membership: anything)

        expect(extension_double)
          .to receive(:call)
          .with(:after_delete_member, role: anything, member: anything, membership: anything)

        delete(
          "#{role_url}?members&member=rspec:group:other",
          env: token_auth_header(role: current_user)
        )
      end
    end

    context 'when the role API extensions are disable' do
      it "does not load the extension classes" do
        expect_any_instance_of(Conjur::Extension::Repository)
          .not_to receive(:extension)
          .with(RolesController::ROLES_API_EXTENSION_KIND)

        delete(
          "#{role_url}?members&member=rspec:group:other",
          env: token_auth_header(role: current_user)
        )
      end
    end
  end
end
