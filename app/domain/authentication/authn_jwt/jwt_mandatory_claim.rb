module Authentication
  module AuthnJwt

    # This class instance holds a JWT standard claim which is
    # mandatory to validate.
    class JwtMandatoryClaim
      attr_reader :name, :value

      def initialize(name:, value:)
        @name = name
        @value = value
      end
    end
  end
end
