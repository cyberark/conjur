require 'command_class'

module Authentication
  module AuthnGce

    Authenticator = CommandClass.new(
      dependencies: {
        validate_resource_restrictions: ValidateResourceRestrictions.new,
        logger:                         Rails.logger
      },
      inputs:       [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :account, :username, :credentials

      def call
        validate_resource_restrictions
      end

      private

      def validate_resource_restrictions
        @validate_resource_restrictions.call(
          account:     account,
          username:    username,
          credentials: credentials
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
        Authentication::AuthnGce::ValidateStatus.new.call
      end
    end
  end
end
