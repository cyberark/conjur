require 'uri'
require 'json'

module Authentication
  module AuthnOidc
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
