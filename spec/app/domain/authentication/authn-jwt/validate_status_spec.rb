# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::ValidateStatus') do

  let(:authenticator_name) { 'authn-jwt' }
  let(:service_id) { "my-service" }
  let(:account) { 'my-account' }
  let(:valid_signing_key_uri) { 'valid-signing-key-uri' }
  let(:valid_signing_key) { 'valid-signing-key' }

  let(:authenticator_status_input) {
    Authentication::AuthenticatorStatusInput.new(
      authenticator_name: authenticator_name,
      service_id: service_id,
      account: account,
      username: "dummy_identity",
      client_ip: "dummy",
      credentials: nil,
      request: nil
    )
  }

  let(:mocked_logger) { double("Mocked logger")  }
  let(:mocked_valid_create_signing_key_provider) { double("Mocked valid create signing key interface")  }
  let(:mocked_invalid_create_signing_key_provider) { double("Mocked invalid create signing key interface")  }
  let(:mocked_valid_fetch_issuer_value) { double("Mocked valid fetch issuer value")  }
  let(:mocked_invalid_fetch_issuer_value) { double("Mocked invalid fetch issuer value")  }
  let(:mocked_invalid_fetch_audience_value) { double("Mocked invalid audience issuer value")  }
  let(:mocked_invalid_fetch_enforced_claims) { double("Mocked invalid fetch enforced claims value")  }
  let(:mocked_invalid_fetch_claim_aliases) { double("Mocked invalid fetch claim aliases value")  }
  let(:mocked_valid_identity_from_decoded_token_provider) { double("Mocked valid identity from decoded token provider")  }
  let(:mocked_valid_identity_configured_properly) { double("Mocked valid identity configured properly")  }
  let(:mocked_invalid_identity_configured_properly) { double("Mocked invalid identity configured properly")  }
  let(:mocked_valid_validate_webservice_is_whitelisted) { double("Mocked valid validate webservice is whitelisted")  }
  let(:mocked_invalid_validate_webservice_is_whitelisted) { double("Mocked invalid validate webservice is whitelisted")  }
  let(:mocked_valid_validate_can_access_webservice) { double("Mocked valid validate can access webservice")  }
  let(:mocked_invalid_validate_can_access_webservice) { double("Mocked invalid validate can access webservice")  }
  let(:mocked_valid_validate_webservice_exists) { double("Mocked valid validate wevservice exists")  }
  let(:mocked_invalid_validate_webservice_exists) { double("Mocked invalid validate wevservice exists")  }
  let(:mocked_valid_validate_account_exists) { double("Mocked valid validate account exists")  }
  let(:mocked_invalid_validate_account_exists) { double("Mocked invalid validate account exists")  }
  let(:mocked_enabled_authenticators) { double("Mocked logger")  }
  let(:mocked_validate_identity_not_configured_properly) { double("MockedValidateIdentityConfiguredProperly") }

  let(:create_signing_key_configuration_is_invalid_error) { "Create signing key configuration is invalid" }
  let(:fetch_issuer_configuration_is_invalid_error) { "Fetch issuer configuration is invalid" }
  let(:fetch_audience_configuration_is_invalid_error) { "Fetch audience configuration is invalid" }
  let(:fetch_enforced_claims_configuration_is_invalid_error) { "Fetch enforced claims configuration is invalid" }
  let(:fetch_claim_aliases_configuration_is_invalid_error) { "Fetch claim aliases configuration is invalid" }
  let(:webservice_is_not_whitelisted_error) { "Webservice is not whitelisted" }
  let(:user_cant_access_webservice_error) { "User cant access webservice" }
  let(:webservice_does_not_exist_error) { "Webservice does not exist" }
  let(:account_does_not_exist_error) { "Account does not exist" }
  let(:identity_not_configured_properly) { "Identity not configured properly" }
  let(:mocked_valid_signing_key_provider) { double("Mocked valid signing key interface")  }

  before(:each) do
    allow(mocked_valid_create_signing_key_provider).to(
      receive(:call).and_return(mocked_valid_signing_key_provider)
    )

    allow(mocked_valid_signing_key_provider).to(
      receive(:call).and_return(valid_signing_key)
    )

    allow(mocked_invalid_create_signing_key_provider).to(
      receive(:call).and_raise(create_signing_key_configuration_is_invalid_error)
    )

    allow(mocked_valid_fetch_issuer_value).to(
      receive(:call).and_return(nil)
    )

    allow(mocked_invalid_fetch_issuer_value).to(
      receive(:call).and_raise(fetch_issuer_configuration_is_invalid_error)
    )

    allow(mocked_invalid_fetch_audience_value).to(
      receive(:call).and_raise(fetch_audience_configuration_is_invalid_error)
    )

    allow(mocked_invalid_fetch_enforced_claims).to(
      receive(:call).and_raise(fetch_enforced_claims_configuration_is_invalid_error)
    )
    allow(mocked_invalid_fetch_claim_aliases).to(
      receive(:call).and_raise(fetch_claim_aliases_configuration_is_invalid_error)
    )

    allow(mocked_valid_identity_from_decoded_token_provider).to(
      receive(:new).and_return(mocked_valid_identity_configured_properly)
    )

    allow(mocked_valid_identity_configured_properly).to(
      receive(:validate_identity_configured_properly).and_return(nil)
    )

    allow(mocked_validate_identity_not_configured_properly).to(
      receive(:call).and_raise(identity_not_configured_properly)
    )

    allow(mocked_valid_validate_webservice_is_whitelisted).to(
      receive(:call).and_return(nil)
    )

    allow(mocked_invalid_validate_webservice_is_whitelisted).to(
      receive(:call).and_raise(webservice_is_not_whitelisted_error)
    )

    allow(mocked_valid_validate_can_access_webservice).to(
      receive(:call).with(anything()).and_return(nil)
    )

    allow(mocked_invalid_validate_can_access_webservice).to(
      receive(:call).and_raise(user_cant_access_webservice_error)
    )

    allow(mocked_valid_validate_webservice_exists).to(
      receive(:call).and_return(nil)
    )

    allow(mocked_invalid_validate_webservice_exists).to(
      receive(:call).and_raise(webservice_does_not_exist_error)
    )

    allow(mocked_enabled_authenticators).to(
      receive(:new).and_return(mocked_enabled_authenticators)
    )

    allow(mocked_valid_validate_account_exists).to(
      receive(:call).with(account: account).and_return(nil)
    )

    allow(mocked_invalid_validate_account_exists).to(
      receive(:call).with(account: account).and_raise(account_does_not_exist_error)
    )

    allow(mocked_logger).to(
      receive(:debug).and_return(nil)
    )

    allow(mocked_logger).to(
      receive(:info).and_return(nil)
    )

  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "ValidateStatus" do
    context "generic and authenticator validations succeed" do

      subject do
        ::Authentication::AuthnJwt::ValidateStatus.new(
          create_signing_key_provider: mocked_valid_create_signing_key_provider,
          fetch_issuer_value: mocked_valid_fetch_issuer_value,
          identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
          validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
          validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
          validate_webservice_exists: mocked_valid_validate_webservice_exists,
          validate_account_exists: mocked_valid_validate_account_exists,
          logger: mocked_logger
        ).call(
          authenticator_status_input: authenticator_status_input,
          enabled_authenticators: mocked_enabled_authenticators
        )
      end

      it "does not raise an error" do
        expect { subject }.to_not raise_error
      end
    end

    context "generic validation fails" do
      context "account doesnt exist" do

        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_invalid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(account_does_not_exist_error)
        end
      end

      context "user can't access webservice" do

        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_invalid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(user_cant_access_webservice_error)
        end
      end

      context "authenticator webservice does not exist" do

        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_invalid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(webservice_does_not_exist_error)
        end
      end

      context "webservice is not whitelisted" do

        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_invalid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(webservice_is_not_whitelisted_error)
        end
      end

      context "service id does not exist" do

        let(:authenticator_status_input_without_service_id) {
          Authentication::AuthenticatorStatusInput.new(
            authenticator_name: authenticator_name,
            service_id: nil,
            account: account,
            username: "dummy_identity",
            client_ip: "dummy",
            credentials: nil,
            request: nil
          )
        }

        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input_without_service_id,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::ServiceIdMissing)
        end
      end
    end

    context "authenticator validation fails" do
      context "signing key secrets are not configured properly" do
        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_invalid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(create_signing_key_configuration_is_invalid_error)
        end
      end

      context "issuer secrets are not configured properly" do
        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_invalid_fetch_issuer_value,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(fetch_issuer_configuration_is_invalid_error)
        end
      end

      context "audience secret is not configured properly" do
        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            fetch_audience_value: mocked_invalid_fetch_audience_value,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(fetch_audience_configuration_is_invalid_error)
        end
      end

      context "enforced claims is not configured properly" do
        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            fetch_enforced_claims: mocked_invalid_fetch_enforced_claims,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(fetch_enforced_claims_configuration_is_invalid_error)
        end
      end

      context "claim aliases is not configured properly" do
        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            fetch_claim_aliases: mocked_invalid_fetch_claim_aliases,
            identity_from_decoded_token_provider_class: mocked_valid_identity_from_decoded_token_provider,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(fetch_claim_aliases_configuration_is_invalid_error)
        end
      end

      context "identity secrets are not configured properly" do
        subject do
          ::Authentication::AuthnJwt::ValidateStatus.new(
            create_signing_key_provider: mocked_valid_create_signing_key_provider,
            fetch_issuer_value: mocked_valid_fetch_issuer_value,
            validate_identity_configured_properly: mocked_validate_identity_not_configured_properly,
            validate_webservice_is_whitelisted: mocked_valid_validate_webservice_is_whitelisted,
            validate_role_can_access_webservice: mocked_valid_validate_can_access_webservice,
            validate_webservice_exists: mocked_valid_validate_webservice_exists,
            validate_account_exists: mocked_valid_validate_account_exists,
            logger: mocked_logger
          ).call(
            authenticator_status_input: authenticator_status_input,
            enabled_authenticators: mocked_enabled_authenticators
          )
        end

        it "raises an error" do
          expect { subject }.to raise_error(identity_not_configured_properly)
        end
      end
    end
  end
end
