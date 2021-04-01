# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::Security::ValidateRoleCanAccessWebservice) do
  include_context "security mocks"

  let(:full_access_resource_class) { resource_class('some random resource') }
  let(:no_access_resource_class) { resource_class(nil) }

  let(:nil_user_role_class) { role_class(nil) }
  let(:non_existing_account_role_class) { role_class(nil) }
  let(:full_access_role_class) { role_class(user_role(is_authorized: true)) }
  let(:no_access_role_class) { role_class(user_role(is_authorized: false)) }

  let(:webservice_mock) { mock_webservice(test_account, fake_authenticator_name, "service1") }

  # generates a Resource class which returns the provided object
  def resource_class(returned_resource)
    double('Resource').tap do |resource_class|
      allow(resource_class).to receive(:[]).and_return(returned_resource)
    end
  end

  def role_class(returned_role)
    double('role_class').tap do |role|
      allow(role).to receive(:roleid_from_username).and_return('some-role-id')
      allow(role).to receive(:[]).and_return(returned_role)

      allow(role).to receive(:[])
        .with(/#{test_account}:user:admin/)
        .and_return(user_role(is_authorized: true))

      allow(role).to receive(:[])
        .with(/#{non_existing_account}:user:admin/)
        .and_return(nil)
    end
  end

  context "An authorized webservice and authorized user" do
    subject do
      Authentication::Security::ValidateRoleCanAccessWebservice.new(
        role_class: full_access_role_class,
        resource_class: full_access_resource_class,
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice: webservice_mock,
        account: test_account,
        user_id: test_user_id,
        privilege: 'test-privilege'
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A non-existing webservice and authorized user" do
    subject do
      Authentication::Security::ValidateRoleCanAccessWebservice.new(
        role_class: full_access_role_class,
        resource_class: no_access_resource_class,
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: false),
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice: webservice_mock,
        account: test_account,
        user_id: test_user_id,
        privilege: 'test-privilege'
      )
    end

    it "raises the error raised by validate_webservice_exists" do
      expect { subject }.to raise_error(validate_webservice_exists_error)
    end
  end

  context "An authorized webservice and non-existent user" do
    subject do
      Authentication::Security::ValidateRoleCanAccessWebservice.new(
        role_class: nil_user_role_class,
        resource_class: full_access_resource_class,
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice: webservice_mock,
        account: test_account,
        user_id: test_user_id,
        privilege: 'test-privilege'
      )
    end
    it "raises a RoleNotFound error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::RoleNotFound)
    end
  end

  context "An authorized webservice and unauthorized user" do
    subject do
      Authentication::Security::ValidateRoleCanAccessWebservice.new(
        role_class: no_access_role_class,
        resource_class: full_access_resource_class,
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
      ).call(
        webservice: webservice_mock,
        account: test_account,
        user_id: test_user_id,
        privilege: 'test-privilege'
      )
    end

    it "raises a RoleNotAuthorizedOnResource error" do
      expect { subject }.to raise_error(Errors::Authentication::Security::RoleNotAuthorizedOnResource)
    end
  end

  context "A non-existing account" do
    subject do
      Authentication::Security::ValidateRoleCanAccessWebservice.new(
        role_class: non_existing_account_role_class,
        resource_class: full_access_resource_class,
        validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
        validate_account_exists: mock_validate_account_exists(validation_succeeded: false)
      ).call(
        webservice: webservice_mock,
        account: non_existing_account,
        user_id: test_user_id,
        privilege: 'test-privilege'
      )
    end

    it "raises the error raised by validate_account_exists" do
      expect { subject }.to raise_error(validate_account_exists_error)
    end
  end

  context "when validating the same role a second time" do
    let(:user_id) { 'some-user' }
    let(:user_roleid) { [test_account, 'user', user_id].join(':') }
    let(:user_role_double) do
      double('user_role_double').tap do |ur|
        allow(ur).to receive(:allowed_to?).and_return(true)
      end
    end

    # We can't use the double returned by the +role_class+ function
    # above, because it doesn't constrain the arguments to +:[]+.
    let(:role_class) do
      double('role_class').tap do |rc|
        allow(rc).to receive(:roleid_from_username).and_return(user_roleid)
        allow(rc).to receive(:[])
          .with("#{test_account}:user:admin")
          .and_return(user_role(is_authorized: true))
      end
    end

    subject do
      described_class
        .new(
          role_class: role_class,
          resource_class: full_access_resource_class,
          validate_webservice_exists: mock_validate_webservice_exists(validation_succeeded: true),
          validate_account_exists: mock_validate_account_exists(validation_succeeded: true)
        )
    end

    it "role lookups are not cached" do
      # Simulate two validations. For the first, the role should not
      # be found.
      allow(role_class).to receive(:[]).with(user_roleid).and_return(nil)
      expect do 
        subject.(
          webservice: webservice_mock,
          account: test_account,
          user_id: user_id,
          privilege: 'test-privilege'
        )
      end.to raise_error(Errors::Authentication::Security::RoleNotFound)

      # For the second, the role should be found, and validation
      # should succeed.

      # Note that, because the arguments are the same, this +allow+
      # overwrites the previous one.
      allow(role_class).to receive(:[]).with(user_roleid).and_return(user_role_double)
      expect do 
        subject.(
          webservice: webservice_mock,
          account: test_account,
          user_id: user_id,
          privilege: 'test-privilege'
        )
      end.not_to raise_error
    end
  end
end
