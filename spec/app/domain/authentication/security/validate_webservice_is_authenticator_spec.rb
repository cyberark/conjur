require 'spec_helper'

RSpec.describe Authentication::Security::ValidateWebserviceIsAuthenticator do
  include_context "security mocks"
  
  let(:webservice_id) { "#{fake_authenticator_name}/#{fake_service_id}" }
  let(:same_authenticator) { "#{fake_authenticator_name}/same-authn" }
  let(:different_authenticator) { "diff-authn/service-id" }

  let(:webservice) {
    mock_webservice(test_account, fake_authenticator_name, fake_service_id)
  }

  let(:installed) {
    double(Authentication::InstalledAuthenticators)
  }
  
  context "webservice is an authenticator" do
    let(:configured_authenticators) {
      [ "authn", webservice_id, same_authenticator, different_authenticator ]
    }

    let(:subject) {
      Authentication::Security::ValidateWebserviceIsAuthenticator.new(
        installed_authenticators_class: installed
      ).call(
        webservice: webservice
      )
    }
    
    before do
      allow(installed).to receive(:configured_authenticators).
          and_return(configured_authenticators)
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "webservice is not authenticator" do
    let(:configured_authenticators) {
      [ "authn", same_authenticator, different_authenticator ]
    }
    
    let(:subject) {
      Authentication::Security::ValidateWebserviceIsAuthenticator.new(
        installed_authenticators_class: installed
      ).call(
        webservice: webservice
      )
    }

    before do
      allow(installed).to receive(:configured_authenticators).
          and_return(configured_authenticators)
    end
    
    it "raises an AuthenticatorNotSupported error" do
      expect { subject }.to raise_error(Errors::Authentication::AuthenticatorNotSupported)
    end
  end
end
