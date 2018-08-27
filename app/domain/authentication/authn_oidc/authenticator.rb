module Authentication
  module AuthnOidc

    class Authenticator

      def initialize(env:)
        # initialization code based on ENV config
        @env = env
      end

      def valid?(input)
        # input has 5 attributes:
        #
        #     input.authenticator_name
        #     input.service_id
        #     input.account
        #     input.username
        #     input.password
        #
        # return true for valid credentials, false otherwise

        # returning true by default until we have real code
        true
      end
    end

  end
end
