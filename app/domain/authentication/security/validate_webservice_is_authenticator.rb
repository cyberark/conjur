module Authentication
  module Security
    ValidateWebserviceIsAuthenticator = CommandClass.new(
      dependencies: {
        configured_authenticators: Authentication::InstalledAuthenticators.configured_authenticators
      },
      inputs: %i(webservice)
    ) do
      
      def call
        validate_webservice_is_configured_authenticator
      end

      private

      def validate_webservice_is_configured_authenticator
        raise Errors::Authentication::AuthenticatorNotFound, webservice_id \
          unless @configured_authenticators.include?(webservice_id)
      end

      def webservice_id
        "#{@webservice.authenticator_name}/#{@webservice.service_id}"
      end
    end
  end
end
