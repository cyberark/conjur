require 'spec_helper'

RSpec.describe Authentication::Security do

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

  let (:doubles) { SecurityDoubles.new }
  let (:whitelisted_webservices) do
    ::Authentication::Webservices.new(
      [webservice('service1'), webservice('service2')]
    )
  end

  let (:full_access_resource_class) { resource_class('some random resource') }
  let (:no_access_resource_class) { resource_class(nil) }

  let (:nil_user_role_class) { role_class(nil) }
  let (:full_access_role_class) { role_class(user_role(true)) }
  let (:no_access_role_class) { role_class(user_role(false)) }

  let (:full_access_security_double) do
    Authentication::Security.new(
      role_class: full_access_role_class,
      resource_class: full_access_resource_class
    )
  end
  let (:zero_access_security_double) do
    Authentication::Security.new(
      role_class: no_access_role_class,
      resource_class: no_access_resource_class
    )
  end
  let (:valid_access_request) do
    Authentication::Security::AccessRequest.new(
      webservice: webservice('service1'),
      whitelisted_webservices: whitelisted_webservices,
      user_id: 'some-user'
    )
  end

  context "A request with nothing whitelisted and no permissions" do
    let (:conjur_access_request) do
      Authentication::Security::AccessRequest.new(
        webservice: Authentication::Webservice.from_string('acct', 'authn'),
        whitelisted_webservices: Authentication::Webservices.new([]),
        user_id: 'some-user'
      )
    end
    let (:non_conjur_access_request) do
      Authentication::Security::AccessRequest.new(
        webservice: Authentication::Webservice.from_string('acct', 'authn-blah'),
        whitelisted_webservices: Authentication::Webservices.new([]),
        user_id: 'some-user'
      )
    end
    it "still allows access to the Conjur authenticator" do
      subject = zero_access_security_double
      expect { subject.validate(conjur_access_request) }.to_not raise_error
    end
    it "blocks access to non-Conjur authenticators" do
      subject = zero_access_security_double
      expect { subject.validate(non_conjur_access_request) }.to(
        raise_error(Authentication::Security::NotWhitelisted)
      )
    end
  end
 
  context "A whitelisted, authorized webservice and authorized user" do

    it "validates without error" do
      subject = full_access_security_double
      expect { subject.validate(valid_access_request) }.to_not raise_error
    end
  end

  context "A un-whitelisted, authorized webservice and authorized user" do

    it "raises a NotWhitelisted error" do
      subject = full_access_security_double
      access_request = Authentication::Security::AccessRequest.new(
        webservice: webservice('DOESNT_EXIST'),
        whitelisted_webservices: whitelisted_webservices,
        user_id: 'some-user'
      )
      expect { subject.validate(access_request) }.to(
        raise_error(Authentication::Security::NotWhitelisted)
      )
    end
  end

  context "A whitelisted, unauthorized webservice and authorized user" do

    it "raises a ServiceNotDefined error" do
      subject = Authentication::Security.new(
        role_class: full_access_role_class,
        resource_class: no_access_resource_class
      )
      expect { subject.validate(valid_access_request) }.to(
        raise_error(Authentication::Security::ServiceNotDefined)
      )
    end
  end

  context "A whitelisted, authorized webservice and non-existent user" do

    it "raises a NotAuthorizedInConjur error" do
      subject = Authentication::Security.new(
        role_class: nil_user_role_class,
        resource_class: full_access_resource_class
      )
      expect { subject.validate(valid_access_request) }.to(
        raise_error(Authentication::Security::NotAuthorizedInConjur)
      )
    end
  end

  context "A whitelisted, authorized webservice and unauthorized user" do

    it "raises a NotAuthorizedInConjur error" do
      subject = Authentication::Security.new(
        role_class: no_access_role_class,
        resource_class: full_access_resource_class
      )
      expect { subject.validate(valid_access_request) }.to(
        raise_error(Authentication::Security::NotAuthorizedInConjur)
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

      it "can access the authorized one" do
        subject = Authentication::Security.new(
          role_class: partial_access_role_class,
          resource_class: accessible_resource_class
        )
        expect { subject.validate(valid_access_request) }.to_not raise_error
      end

      it "cannot access the blocked one" do
        subject = Authentication::Security.new(
          role_class: partial_access_role_class,
          resource_class: inaccessible_resource_class
        )
        expect { subject.validate(valid_access_request) }.to(
          raise_error(Authentication::Security::NotAuthorizedInConjur)
        )
      end
    end

  end


end
