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
        class AuthenticatorConfiguration < Authentication::Base::Validations
          schema do
            required(:account).filled(:string)
            required(:service_id).filled(:string)
            required(:provider_uri).filled(:string)
            required(:client_id).filled(:string)
            required(:client_secret).filled(:string)
            required(:claim_mapping).value(:string)

            optional(:redirect_uri).value(:string)
            optional(:response_type).value(:string)
            optional(:provider_scope).value(:string)
            optional(:name).value(:string)
            optional(:token_ttl).value(:string)
            optional(:provider_scope).value(:string)
            optional(:ca_cert).value(:string)
          end
        end
      end
    end
  end
end
