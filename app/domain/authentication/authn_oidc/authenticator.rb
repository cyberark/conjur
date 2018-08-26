module Authentication
  module AuthnLdap

    class Authenticator

      def initialize(env:)
        # initialization code based on ENV config
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
      end
    end

  end
end
