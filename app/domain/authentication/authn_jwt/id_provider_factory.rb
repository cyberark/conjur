module Authentication
  module AuthnJwt
    # Factory for jwt identity providers.
    # If Identity variable is configured factory return the decoded_token_provider
    # If the Identity variable is not configured and there is account field in url factory returns url provider
    # If the above conditions are not met exception is raised
    class IdProviderFactory
      PROVIDERS = {
        "from_url_provider" => Authentication::AuthnJwt::IdFromUrlProvider,
        "from_decoded_token_provider" => Authentication::AuthnJwt::ConjurIdFromDecodedTokenProvider
      }

      def self.relevant_id_provider(authentication_parameters)
        if PROVIDERS["from_decoded_token_provider"].new(authentication_parameters).id_available?
          return PROVIDERS["from_decoded_token_provider"].new(authentication_parameters)
        elsif PROVIDERS["from_url_provider"].new(authentication_parameters).id_available?
          return PROVIDERS["from_url_provider"].new(authentication_parameters)
        end
        raise Errors::Authentication::AuthnJwt::NoRelevantIdentityProvider
      end
    end
  end
end
