require 'cgi'
require 'forwardable'
require 'command_class'

module Authentication
  module AuthnJwt

    Authenticator ||= CommandClass.new(
      dependencies: { },
      inputs: []
    ) do
      extend(Forwardable)

      def call
        true
      end
    end

    class Authenticator
      def valid?(input)
        true
      end
    end
  end
end
