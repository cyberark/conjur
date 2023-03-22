# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      module DataObjects
        class Authenticator

          RESERVED_CLAIMS = %w[iss exp nbf iat jti aud].freeze

          attr_reader(:account, :service_id)

          attr_reader(
            :jwks_uri,
            :provider_uri,
            :public_keys,
            :ca_cert,
            :identity_path,
            :issuer,
            :claim_aliases,
            :token_app_property,
            :audience
          )

          def initialize(
            account:,
            service_id:,
            jwks_uri: nil,
            provider_uri: nil,
            public_keys: nil,
            ca_cert: nil,
            token_app_property: nil,
            identity_path: nil,
            issuer: nil,
            enforced_claims: nil,
            claim_aliases: nil,
            audience: nil,
            token_ttl: 'PT8M'
          )
            @service_id = service_id
            @account = account
            @jwks_uri = jwks_uri
            @provider_uri = provider_uri
            @public_keys = public_keys
            @ca_cert = ca_cert
            @token_app_property = token_app_property
            @identity_path = identity_path
            @issuer = issuer
            @enforced_claims = enforced_claims
            @claim_aliases = claim_aliases
            @audience = audience
            @token_ttl = token_ttl
          end

          def resource_id
            "#{@account}:webservice:conjur/authn-jwt/#{@service_id}"
          end

          def token_ttl
            ActiveSupport::Duration.parse(@token_ttl.to_s)
          rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
            raise Errors::Authentication::DataObjects::InvalidTokenTTL.new(resource_id, @token_ttl)
          end

          def enforced_claims
            @enforced_claims.to_s.split(',').map(&:strip)
          end

          def reserved_claims
            RESERVED_CLAIMS
          end

          def claim_aliases_lookup
            return {} if @claim_aliases.nil?

            Hash[@claim_aliases.to_s.split(',').map{|s| s.split(':').map(&:strip)}]
          end
        end
      end
    end
  end
end
