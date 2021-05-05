module Authentication
  module AuthnJwt

    # This class instance holds a JWT standard claim
    class JwtClaim
      attr_reader :name, :value

      def initialize(name:, value:)
        @name = name
        @value = value
      end
    end
  end
end
