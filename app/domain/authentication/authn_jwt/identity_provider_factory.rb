module Authentication
  module AuthnJwt
    # Factory for jwt identity providers.
    # If Identity variable is configured factory return the decoded_token_provider
    # If the Identity variable is not configured and there is account field in url factory returns url provider
    # If the above conditions are not met exception is raised
    class IdentityProviderFactory
      attr_accessor :from_url_provider, :from_decoded_token_provider

      def initialize(authentication_parameters)
        @from_url_provider = Authentication::AuthnJwt::IdentityFromUrlProvider.new(authentication_parameters)
        @from_decoded_token_provider = Authentication::AuthnJwt::IdentityFromDecodedTokenProvider.new(authentication_parameters)
      end

      def relevant_id_provider
        if @from_decoded_token_provider.identity_available?
          Rails.logger.debug(LogMessages::Authentication::AuthnJwt::URL_IDENTITY_PROVIDER_SELECTED.new)
          return @from_decoded_token_provider
        elsif @from_url_provider.identity_available?
          Rails.logger.debug(LogMessages::Authentication::AuthnJwt::DECODED_TOKEN_IDENTITY_PROVIDER_SELECTED.new)
          return @from_url_provider
        end
        raise Errors::Authentication::AuthnJwt::NoRelevantIdentityProvider
      end
    end
  end
end
