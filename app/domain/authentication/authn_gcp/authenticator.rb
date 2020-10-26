require 'command_class'

module Authentication
  module AuthnGcp

    Authenticator = CommandClass.new(
      dependencies: {
        validate_resource_restrictions: Authentication::Common::ValidateResourceRestrictions.new,
        authentication_request_class:   AuthenticationRequest,
        logger:                         Rails.logger
      },
      inputs:       [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :authenticator_name, :service_id, :account, :username, :credentials

      def call
        authentication_request = create_authentication_request
        validate_resource_restrictions(authentication_request)
      end

      private

      def create_authentication_request
        @authentication_request_class.new(
          decoded_token: credentials
        )
      end

      def validate_resource_restrictions(authentication_request)
        @validate_resource_restrictions.call(
          authenticator_name: authenticator_name,
          service_id: service_id,
          account: account,
          host_name: username,
          constraints: Restrictions::CONSTRAINTS,
          authentication_request: authentication_request
        )
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
      def valid?(input)
        call(authenticator_input: input)
      end

      def status(authenticator_status_input:)
        Authentication::AuthnGcp::ValidateStatus.new.call
      end
    end
  end
end
