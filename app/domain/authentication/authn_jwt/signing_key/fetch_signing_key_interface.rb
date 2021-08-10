module Authentication
  module AuthnJwt
    module SigningKey
      class FetchSigningKeyInterface
        def fetch_signing_key; end

        def valid_configuration?; end
      end
    end
  end
end
