require 'json'

module Authentication
  module OAuth

    # This class represents a set of OAuth 2.0 Identity Provider certificates
    # Each object stores the retrieved JWKs and the algorithms that signed them
    class ProviderCertificates
      attr_reader :jwks
      attr_reader :algorithms

      def initialize(jwks, algorithms)
        @jwks = jwks
        @algorithms = algorithms
      end
    end
  end
end
