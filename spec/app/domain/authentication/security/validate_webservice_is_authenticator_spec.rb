require 'spec_helper'

RSpec.describe(Authentication::Security::ValidateWebserviceIsAuthenticator) do
  include_context "security mocks"
  
  let(:webservice_id) { "#{fake_authenticator_name}/#{fake_service_id}" }
  let(:same_authenticator) { "#{fake_authenticator_name}/same-authn" }
  let(:different_authenticator) { "diff-authn/service-id" }

  let(:webservice) do
    mock_webservice(test_account, fake_authenticator_name, fake_service_id)
  end

  let(:installed) do
    double(Authentication::InstalledAuthenticators)
  end
  
  context "webservice is an authenticator" do
    let(:configured_authenticators) do
      [ "authn", webservice_id, same_authenticator, different_authenticator ]
    end

    let(:subject) do
      Authentication::Security::ValidateWebserviceIsAuthenticator.new(
        installed_authenticators_class: installed
      ).call(
        webservice: webservice
      )
    end
    
    before do
      allow(installed).to receive(:configured_authenticators)
        .and_return(configured_authenticators)
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "webservice is not authenticator" do
    let(:configured_authenticators) do
      [ "authn", same_authenticator, different_authenticator ]
    end
    
    let(:subject) do
      Authentication::Security::ValidateWebserviceIsAuthenticator.new(
        installed_authenticators_class: installed
      ).call(
        webservice: webservice
      )
    end

    before do
      allow(installed).to receive(:configured_authenticators)
        .and_return(configured_authenticators)
    end
    
    it "raises an AuthenticatorNotSupported error" do
      expect { subject }.to raise_error(Errors::Authentication::AuthenticatorNotSupported)
    end
  end

  context "authenticator with no service id" do
    let(:webservice) do
      mock_webservice(test_account, fake_authenticator_name, "")
    end
    let(:configured_authenticators) do
      [ "authn", fake_authenticator_name ]
    end

    let(:subject) do
      Authentication::Security::ValidateWebserviceIsAuthenticator.new(
        installed_authenticators_class: installed
      ).call(
        webservice: webservice
      )
    end

    before do
      allow(installed).to receive(:configured_authenticators)
                            .and_return(configured_authenticators)
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

end
