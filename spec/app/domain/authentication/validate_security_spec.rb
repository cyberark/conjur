# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authentication::ValidateSecurity do

  # create an example webservice
  def webservice(service_id, account: 'my-acct', authenticator_name: 'authn-x')
    ::Authentication::Webservice.new(
      account: account,
      authenticator_name: authenticator_name,
      service_id: service_id
    )
  end

  # generates user_role authorized for all or no services
  def user_role(is_authorized)
    double('user_role').tap do |role|
      allow(role).to receive(:allowed_to?).and_return(is_authorized)
    end
  end

  # generates user_role authorized for specific service
  def user_role_for_service(authorized_service)
    double('user_role').tap do |role|
      allow(role).to(receive(:allowed_to?)) do |_, resource|
        resource == authorized_service
      end
    end
  end

  # generates a Role class which returns the provided user_role
  def role_class(returned_role)
    double(
      'Role',
       :roleid_from_username => 'some-role-id',
       :[] => returned_role
    )
  end

  # generates a Resource class which returns the provided object
  def resource_class(returned_resource)
    double('Resource').tap do |resource|
      allow(resource).to receive(:[]).and_return(returned_resource)
    end
  end

  let (:blank_env) { nil }

  let (:two_authenticator_env) { "authn-x/service1, authn-x/service2" }

  let(:default_authenticator_mock) do
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:authenticator_name).and_return("authn")
    end
  end

  let(:random_authenticator_mock) do
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:authenticator_name).and_return("authn-x")
    end
  end

  let (:full_access_resource_class) { resource_class('some random resource') }
  let (:no_access_resource_class) { resource_class(nil) }

  let (:nil_user_role_class) { role_class(nil) }
  let (:full_access_role_class) { role_class(user_role(true)) }
  let (:no_access_role_class) { role_class(user_role(false)) }

  context "A whitelisted, authorized webservice and authorized user" do
    subject do
      Authentication::ValidateSecurity.new(
        role_class: full_access_role_class,
        webservice_resource_class: full_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: 'my-acct',
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A un-whitelisted, authorized webservice and authorized user" do
    subject do
      Authentication::ValidateSecurity.new(
        role_class: full_access_role_class,
        webservice_resource_class: full_access_resource_class
      ).(
        webservice: webservice('DOESNT_EXIST'),
          account: 'my-acct',
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises a NotWhitelisted error" do
      expect { subject }.to raise_error(Authentication::NotWhitelisted)
    end
  end

  context "A whitelisted, unauthorized webservice and authorized user" do
    subject do
      Authentication::ValidateSecurity.new(
        role_class: full_access_role_class,
        webservice_resource_class: no_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: 'my-acct',
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises a ServiceNotDefined error" do
      expect { subject }.to raise_error(Authentication::ServiceNotDefined)
    end
  end

  context "A whitelisted, authorized webservice and non-existent user" do
    subject do
      Authentication::ValidateSecurity.new(
        role_class: nil_user_role_class,
        webservice_resource_class: full_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: 'my-acct',
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end
    it "raises a NotDefinedInConjur error" do
      expect { subject }.to raise_error(Authentication::NotDefinedInConjur)
    end
  end

  context "A whitelisted, authorized webservice and unauthorized user" do
    subject do
      Authentication::ValidateSecurity.new(
        role_class: no_access_role_class,
        webservice_resource_class: full_access_resource_class
      ).(
        webservice: webservice('service1'),
          account: 'my-acct',
          user_id: 'some-user',
          enabled_authenticators: two_authenticator_env
      )
    end

    it "raises a NotAuthorizedInConjur error" do
      expect { subject }.to raise_error(Authentication::NotAuthorizedInConjur
      )
    end
  end

  context "Two whitelisted, authorized webservices" do
    context "and a user authorized for only one on them" do
      let (:webservice_resource) { 'CAN ACCESS ME' }
      let (:partial_access_role_class) do
        role_class(user_role_for_service(webservice_resource))
      end
      let (:accessible_resource_class) { resource_class(webservice_resource) }
      let (:inaccessible_resource_class) { resource_class('CANNOT ACCESS ME') }

      context "when accessing the authorized one" do
        subject do
          Authentication::ValidateSecurity.new(
            role_class: partial_access_role_class,
            webservice_resource_class: accessible_resource_class
          ).(
            webservice: webservice('service1'),
              account: 'my-acct',
              user_id: 'some-user',
              enabled_authenticators: two_authenticator_env
          )
        end

        it "succeeds" do
          expect { subject }.to_not raise_error
        end
      end

      context "when accessing the blocked one" do
        subject do
          Authentication::ValidateSecurity.new(
            role_class: partial_access_role_class,
            webservice_resource_class: inaccessible_resource_class
          ).(
            webservice: webservice('service1'),
              account: 'my-acct',
              user_id: 'some-user',
              enabled_authenticators: two_authenticator_env
          )
        end

        it "fails" do
          expect { subject }.to raise_error(Authentication::NotAuthorizedInConjur)
        end
      end
    end
  end

  context "An ENV lacking CONJUR_AUTHENTICATORS" do
    subject do
      Authentication::ValidateSecurity.new(
        role_class: full_access_role_class,
        webservice_resource_class: full_access_resource_class
      ).(
        webservice: default_authenticator_mock,
          account: 'my-acct',
          user_id: 'some-user',
          enabled_authenticators: blank_env
      )
    end

    it "the default Conjur authenticator is included in whitelisted webservices" do
      expect { subject }.to_not raise_error
    end
  end
end
