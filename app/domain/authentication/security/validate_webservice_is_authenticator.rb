module Authentication

  module Security

    ValidateWebserviceIsAuthenticator = CommandClass.new(
      dependencies: {
        installed_authenticators_class: Authentication::InstalledAuthenticators
      },
      inputs: %i[webservice]
    ) do
      
      def call
        validate_webservice_is_configured_authenticator
      end

      private

      def validate_webservice_is_configured_authenticator
        raise Errors::Authentication::AuthenticatorNotSupported, webservice_id \
          unless @installed_authenticators_class.configured_authenticators.include?(webservice_id)
      end

      def webservice_id
        @webservice.service_id.blank? ? @webservice.authenticator_name : "#{@webservice.authenticator_name}/#{@webservice.service_id}"
      end
    end
  end
end
