module Authentication
  module AuthnJwt
    class FetchSigningKeyInterface
      def initialize(authenticator_parameters); end
      def create; end
      def has_valid_configuration?; end
    end
  end
end
