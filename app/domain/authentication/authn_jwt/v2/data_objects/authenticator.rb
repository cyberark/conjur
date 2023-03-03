# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      module DataObjects
        class Authenticator

          # Notes:
          #  - Starting with support for JWKS.  Local public keys will be added later.

          REQUIRED_VARIABLES = %i[].freeze
          OPTIONAL_VARIABLES = %i[jwks_uri public_keys ca_cert token_app_property identity_path issuer enforced_claims claim_aliases audience token_ttl].freeze

          attr_reader(:account, :service_id)

          attr_reader(
            :jwks_uri,
            :public_keys,
            :ca_cert,
            :token_app_property,
            :identity_path,
            :issuer,
            :enforced_claims,
            :claim_aliases,
            :audience
            # :client_id,
            # :client_secret,
            # :claim_mapping,
            # :account,
            # :service_id,
            # :redirect_uri,
            # :response_type
          )

          def initialize(
            account:,
            service_id:,
            jwks_uri: nil,
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
            "#{account}:webservice:conjur/authn-jwt/#{service_id}"
          end

          def token_ttl
            ActiveSupport::Duration.parse(@token_ttl)
          rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
            raise Errors::Authentication::DataObjects::InvalidTokenTTL.new(resource_id, @token_ttl)
          end

        end
      end
    end
  end
end
