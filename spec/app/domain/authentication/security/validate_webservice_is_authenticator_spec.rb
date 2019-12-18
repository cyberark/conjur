require 'spec_helper'

RSpec.describe Authentication::Security::ValidateWebserviceIsAuthenticator do
  include_context "security mocks"
  
  let(:webservice_id) { "#{fake_authenticator_name}/#{fake_service_id}" }
  let(:same_authenticator) { "#{fake_authenticator_name}/same-authn" }
  let(:different_authenticator) { "diff-authn/service-id" }

  let(:webservice) {
    mock_webservice(test_account, fake_authenticator_name, fake_service_id)
  }
  
  context "webserve is an authenticator" do
    let(:configured_authenticators) {
      [ "authn", webservice_id, same_authenticator, different_authenticator ]
    }
    
    let(:subject) {
      Authentication::Security::ValidateWebserviceIsAuthenticator.new(
        configured_authenticators: configured_authenticators
      ).call(
        webservice: webservice
      )
    }

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "webserve is not authenticator" do
    let(:configured_authenticators) {
      [ "authn", same_authenticator, different_authenticator ]
    }
    
    let(:subject) {
      Authentication::Security::ValidateWebserviceIsAuthenticator.new(
        configured_authenticators: configured_authenticators
      ).call(
        webservice: webservice
      )
    }
    
    it "raises an AuthenticatorNotFound error" do
      expect { subject }.to raise_error(Errors::Authentication::AuthenticatorNotFound)
    end
  end
end
