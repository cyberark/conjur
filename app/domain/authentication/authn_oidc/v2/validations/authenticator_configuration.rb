# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      module Validations

        # This class validates the configuration of the OIDC Authenticator as defined
        # by the authenticator's variables.
        #
        # All required and optional variables should be defined here, as well as any
        # the validation of those input's values.
        #
        # This validations are executed against the data loaded from Conjur variables when
        # the authenicator is loaded via the AuthenticatorRepository.
        class AuthenticatorConfiguration < Dry::Validation::Contract
          option :utils

          schema do
            required(:account).value(:string)
            required(:service_id).value(:string)
            required(:provider_uri).value(:string)
            required(:client_id).value(:string)
            required(:client_secret).value(:string)
            required(:claim_mapping).value(:string)

            optional(:redirect_uri).value(:string)
            optional(:response_type).value(:string)
            optional(:provider_scope).value(:string)
            optional(:name).value(:string)
            optional(:token_ttl).value(:string)
            optional(:provider_scope).value(:string)
            optional(:ca_cert).value(:string)
          end

          # Verify that `provider_uri` has a secret value set if variable is present
          rule(:provider_uri, :service_id, :account) do
            if values[:provider_uri].empty?
              utils.failed_response(
                key: key,
                error: Errors::Conjur::RequiredSecretMissing.new(
                  "#{values[:account]}:variable:conjur/authn-oidc/#{values[:service_id]}/provider-uri"
                )
              )
            end
          end
        end
      end
    end
  end
end
