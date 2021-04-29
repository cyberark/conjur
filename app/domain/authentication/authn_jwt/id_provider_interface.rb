module Authentication
  module AuthnJwt
    class IdProviderInterface
      def initialize(authentication_parameters); end
      def provide_jwt_id; end
      def id_available?; end
    end
  end
end

