require 'command_class'

module Authentication
  module AuthnGcp

    Authenticator = CommandClass.new(
      dependencies: {
        logger: Rails.logger
      },
      inputs:       [:authenticator_input]
    ) do

      extend Forwardable
      def_delegators :@authenticator_input, :account, :credentials, :username

      def call
        # TODO: validate resource restrictions
        # Note: 'credentials' is now the decoded token. you can access its
        # fields with an argument reader (e.g credentials.project_id)
      end

      private

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
    end
  end
end
