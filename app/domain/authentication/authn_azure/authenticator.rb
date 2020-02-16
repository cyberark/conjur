require 'command_class'

module Authentication
  module AuthnAzure

    Log = LogMessages::Authentication
    Err = Errors::Authentication::AuthnAzure

    Authenticator = CommandClass.new(
      dependencies: {
        fetch_authenticator_secrets:    Authentication::Util::FetchAuthenticatorSecrets.new,
        validate_application_identity:  ValidateApplicationIdentity.new,
        logger:                         Rails.logger
      },
      inputs: [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :service_id, :authenticator_name, :account, :username, :request, :credentials

      def call
        validate_application_identity
      end

      private

      # expecting to receive xms_mirid and oid as inputs (either global instance or function). This will change to hash map.
      def validate_application_identity
        @validate_application_identity.(
            service_id: service_id,
            account: account,
            username: username,
            xms_mirid: decoded_token["xms_mirid"],
            oid: decoded_token["oid"]
        )
      end

      def provider_uri
        azure_authenticator_secrets["provider-uri"]
      end

      def azure_authenticator_secrets
        @azure_authenticator_secrets ||= @fetch_authenticator_secrets.(
          service_id: service_id,
          conjur_account: account,
          authenticator_name: authenticator_name,
          required_variable_names: required_variable_names
        )
      end

      def required_variable_names
        @required_variable_names ||= %w(provider-uri)
      end
    end

    class Authenticator
      # This delegates to all the work to the call method created automatically
      # by CommandClass
      #
      # This is needed because we need `valid?` to exist on the Authenticator
      # class, but that class contains only a metaprogramming generated
      # `call(authenticator_input:)` method.  The methods we define in the
      # block passed to `CommandClass` exist only on the private internal
      # `Call` objects created each time `call` is run.
      #
      def valid?(input)
        call(authenticator_input: input)
      end
    end
  end
end
