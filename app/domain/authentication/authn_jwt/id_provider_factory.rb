module Authentication
  module AuthnJwt
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
        raise "Unable to get jwt identity"
      end
    end
  end
end
