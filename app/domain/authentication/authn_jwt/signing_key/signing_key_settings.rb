module Authentication
  module AuthnJwt
    module SigningKey
      # This class is responsible for JWKS fetching related settings of the authenticator
      class SigningKeySettings
        attr_reader :uri, :type

        def initialize(uri:,
                       type:)
          @uri = uri
          @type = type
        end
      end
    end
  end
end
