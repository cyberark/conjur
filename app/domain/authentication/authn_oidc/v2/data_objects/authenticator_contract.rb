# frozen_string_literal: true

module Authentication
  module AuthnOidc
    module V2
      module DataObjects

        # This class handles all validation for the JWT authenticator. This contract
        # is executed against the data gleaned from Conjur variables when the authenicator
        # is loaded via the AuthenticatorRepository.

        class AuthenticatorContract < Dry::Validation::Contract
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
          end

          # Verify that `provider_uri` has a secret value set if variable is present
          rule(:provider_uri, :service_id, :account) do
            if values[:provider_uri].empty?
              utils.failed_response(
                key: key,
                error: Errors::Conjur::RequiredSecretMissing.new(
                  "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/provider-uri"
                )
              )
            end
          end
        end
      end
    end
  end
end
