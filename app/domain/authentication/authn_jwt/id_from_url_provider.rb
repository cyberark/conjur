module Authentication
  module AuthnJwt
    # Provides jwt identity from information in the URL
    class IdFromUrlProvider < IdProviderInterface
      def initialize(authentication_parameters)
        @authentication_parameters = authentication_parameters
      end

      def provide_jwt_id
        @authentication_parameters.authentication_input[:username]
      end

      def id_available?
        !@authentication_parameters.authentication_input[:username].nil?
      end
    end
  end
end

