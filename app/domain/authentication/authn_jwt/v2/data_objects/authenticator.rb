# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      module DataObjects
        class Authenticator

          DENYLIST = %w[iss exp nbf iat jti aud].freeze

          REQUIRED_VARIABLES = %i[].freeze
          OPTIONAL_VARIABLES = %i[jwks_uri public_keys ca_cert token_app_property identity_path issuer enforced_claims claim_aliases audience token_ttl provider_uri].freeze

          attr_reader(:account, :service_id)

          attr_reader(
            :jwks_uri,
            :provider_uri,
            :public_keys,
            :ca_cert,
            :identity_path,
            :issuer,
            :claim_aliases,
            :audience

            # moved to methods below to allow for "validation"
            # :enforced_claims,
            # :token_app_property,
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
            # ensure we have a string so we can split safely to generate the hash lookup
            @claim_aliases = claim_aliases.to_s
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

          def token_app_property
            token_app_property = @token_app_property.to_s
            # Ensure claim contain only "allowed" characters (alpha-numeric, and: "-", "_", "/", ".")
            unless token_app_property.count('a-zA-Z0-9\/\-_\.') == token_app_property.length
              raise Errors::Authentication::AuthnJwt::InvalidTokenAppPropertyValue,
                "token-app-property can only contain alpha-numeric characters, '-', '_', '/', and '.'"
            end

            token_app_property
          end

          def enforced_claims
            @claims ||= begin
              claims = @enforced_claims.to_s.split(',').map(&:strip)

              claims.each do |claim|
                # Ensure claim contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
                unless claim.count('a-zA-Z0-9\/\-_\.') == claim.length
                  raise Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName.new(
                    claim,
                    '[a-zA-Z0-9\/\-_\.]+'
                  )
                end
              end
              claims
            end
          end

          def denylist
            DENYLIST
          end

          # TODO: The raise here feels super dirty. I need to find a cleaner solution...
          def claim_aliases_lookup
            @claim_aliases_lookup ||= begin
              {}.tap do |rtn|
                @claim_aliases.split(',').each do |claim_alias|
                  key, value = claim_alias.split(':').map(&:strip)

                  # If alias is defined multiple times
                  if rtn.key?(key)
                    raise Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError.new('annotation name', key)

                    # If alias target is defined multiple times
                  elsif rtn.invert.key?(value)
                    raise Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError.new('claim name', value)

                  # Ensure alias contains only "allowed" characters (alpha-numeric, plus: "-", "_", ".")
                  #
                  # TODO: This error needs to be updated to show the invalid character(s)
                  elsif key.count('a-zA-Z0-9\-_\.') != key.length
                    raise Errors::Authentication::AuthnJwt::ClaimAliasNameInvalidCharacter, key

                  # Ensure target claim contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
                  elsif value.count('a-zA-Z0-9\/\-_\.') != value.length
                    raise Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName.new(
                      value,
                      '[a-zA-Z0-9\/\-_\.]+'
                    )
                  end

                  # If alias or target is in denylist
                  if DENYLIST.include?(key)
                    raise Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList.new(key, DENYLIST)
                  elsif DENYLIST.include?(value)
                    raise Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList.new(value, DENYLIST)
                  end

                  rtn[key] = value
                end
              end
            end
          end
        end
      end
    end
  end
end
