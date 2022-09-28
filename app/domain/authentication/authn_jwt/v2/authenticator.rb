module Authentication
  module AuthnJwt
    module V2
      module DataObjects
        class Authenticator

          attr_reader :issuer, :audience, :identifying_claim, :jwks_uri, :account, :service_id

          def initialize(issuer:, audience:, jwks_uri:, account:, service_id:, token_app_property: nil, identifying_claim: nil, name: nil)
            @issuer = issuer
            @audience = audience
            @jwks_uri = jwks_uri
            @account = account
            @service_id = service_id
            @identifying_claim = identifying_claim || token_app_property
            @name = name
          end

          def algorithms
            %w[RS256]
          end

          def name
            @name || @service_id.titleize
          end

          def resource_id
            "#{account}:webservice:conjur/authn-jwt/#{service_id}"
          end

        end
      end
    end
  end
end
