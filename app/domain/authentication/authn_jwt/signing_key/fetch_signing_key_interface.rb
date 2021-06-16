module Authentication
  module AuthnJwt
    module SigningKey
      class FetchSigningKeyInterface
        def call; end

        def valid_configuration?; end
      end
    end
  end
end
