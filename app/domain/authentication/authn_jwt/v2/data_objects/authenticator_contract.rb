# frozen_string_literal: true

module Authentication
  module AuthnJwt
    module V2
      module DataObjects

        # This class handles all validation for the JWT authenticator. This contract
        # is executed against the data gleaned from Conjur variables when the authenicator
        # is loaded via the AuthenticatorRepository.

        class AuthenticatorContract < Dry::Validation::Contract
          schema do
            required(:account).value(:string)
            required(:service_id).value(:string)

            optional(:jwks_uri).value(:string)
            optional(:public_keys).value(:string)
            optional(:ca_cert).value(:string)
            optional(:token_app_property).value(:string)
            optional(:identity_path).value(:string)
            optional(:issuer).value(:string)
            optional(:enforced_claims).value(:string)
            optional(:claim_aliases).value(:string)
            optional(:audience).value(:string)
            optional(:token_ttl).value(:string)
            optional(:provider_uri).value(:string)
          end

          # Verify that only one of `jwks-uri`, `public-keys`, and `provider-uri` are set
          rule(:jwks_uri, :public_keys, :provider_uri) do
            if %i[jwks_uri provider_uri public_keys].select { |key| values[key].present? }.count > 1
              key.failure(
                exception: Errors::Authentication::AuthnJwt::InvalidSigningKeySettings,
                text: 'jwks-uri and provider-uri cannot be defined simultaneously'
              )
            end
          end

          # Verify that `issuer` has a secret value set if the variable is present
          rule(:issuer, :account, :service_id) do
            if values[:issuer] == ''
              key.failure(
                exception: Errors::Conjur::RequiredSecretMissing,
                text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/issuer"
              )
            end
          end

          # Verify that `claim_aliases` has a secret value set if variable is present
          rule(:claim_aliases, :account, :service_id) do
            if values[:claim_aliases] == ''
              key.failure(
                exception: Errors::Conjur::RequiredSecretMissing,
                text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/claim-aliases"
              )
            end
          end

          # Verify that `provider_uri` has a secret value set if variable is present
          rule(:provider_uri, :service_id, :account) do
            if values[:provider_uri] == ''
              key.failure(
                exception: Errors::Conjur::RequiredSecretMissing,
                text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/provider-uri"
              )
            end
          end

          # Verify that `jwks-uri`, `public-keys`, or `provider-uri` has a secret value set if a variable exists
          rule(:jwks_uri, :public_keys, :provider_uri, :account, :service_id) do
            empty_variables = %i[jwks_uri provider_uri public_keys].select {|key, _| values[key] == '' && !values[key].nil? }
            if empty_variables.count == 1
              # Performing this insanity to match current functionality :P
              if empty_variables.first == :provider_uri
                key.failure(
                  exception: Errors::Authentication::AuthnJwt::InvalidSigningKeySettings,
                  text: 'Failed to find a JWT decode option. Either `jwks-uri` or `public-keys` variable must be set.'
                )
              else
                key.failure(
                  exception: Errors::Conjur::RequiredSecretMissing,
                  text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/#{empty_variables.first.to_s.dasherize}"
                )
              end
            end
          end

          # Verify that a variable has been created for one of: `jwks-uri`, `public-keys`, or `provider-uri`
          rule(:jwks_uri, :public_keys, :provider_uri) do
            if %i[jwks_uri provider_uri public_keys].all? { |item| values[item].nil? }
              key.failure(
                exception: Errors::Authentication::AuthnJwt::InvalidSigningKeySettings,
                text: 'One of the following must be defined: jwks-uri, public-keys, or provider-uri'
              )
            end
          end

          # Verify that a variable has been set for one of: `jwks-uri`, `public-keys`, or `provider-uri`
          rule(:jwks_uri, :public_keys, :provider_uri) do
            if %i[jwks_uri provider_uri public_keys].all? { |item| values[item].blank? }
              key.failure(
                exception: Errors::Authentication::AuthnJwt::InvalidSigningKeySettings,
                text: 'Failed to find a JWT decode option. Either `jwks-uri` or `public-keys` variable must be set'
              )
            end
          end

          # Verify that `token_app_property` has a secret value set if the variable is present
          rule(:token_app_property, :account, :service_id) do
            if values[:token_app_property] == ''
              key.failure(
                exception: Errors::Conjur::RequiredSecretMissing,
                text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/token-app-property"
              )
            end
          end

          # Verify that `token_app_property` includes only valid characters
          rule(:token_app_property) do
            unless values[:token_app_property].to_s.count('a-zA-Z0-9\/\-_\.') == values[:token_app_property].to_s.length
              key.failure(
                exception: Errors::Authentication::AuthnJwt::InvalidTokenAppPropertyValue,
                text: "token-app-property can only contain alpha-numeric characters, '-', '_', '/', and '.'"
              )
            end
          end

          # Verify that `token_app_property` does not include double slashes
          rule(:token_app_property) do
            if values[:token_app_property].to_s.match(/\/\//)
              key.failure(
                exception: Errors::Authentication::AuthnJwt::InvalidTokenAppPropertyValue,
                text: "token-app-property includes `//`"
              )
            end
          end

          # Verify that `audience` has a secret value set if variable is present
          rule(:audience, :service_id, :account) do
            if values[:audience] == ''
              key.failure(
                exception: Errors::Conjur::RequiredSecretMissing,
                text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/audience"
              )
            end
          end

          # Verify that `identity_path` has a secret value set if variable is present
          rule(:identity_path, :service_id, :account) do
            if values[:identity_path] == ''
              key.failure(
                exception: Errors::Conjur::RequiredSecretMissing,
                text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/identity-path"
              )
            end
          end

          # Verify that `enforced_claims` has a secret value set if variable is present
          rule(:enforced_claims, :service_id, :account) do
            if values[:enforced_claims] == ''
              key.failure(
                exception: Errors::Conjur::RequiredSecretMissing,
                text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/enforced-claims"
              )
            end
          end

          # Verify that claim values contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
          rule(:enforced_claims) do
            values[:enforced_claims].to_s.split(',').map(&:strip).each do |claim|
              next if claim.count('a-zA-Z0-9\/\-_\.') == claim.length

              key.failure(
                exception: Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName,
                text: '',
                args: {
                  arg1: claim,
                  arg2: '[a-zA-Z0-9\/\-_\.]+'
                }
              )
            end
          end

          # Verify that there are no reserved claims in the enforced claims list
          rule(:enforced_claims) do
            denylist = %w[iss exp nbf iat jti aud]
            (values[:enforced_claims].to_s.split(',').map(&:strip) & denylist).each do |claim|
              key.failure(
                exception: Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList,
                args: {
                  arg1: claim,
                  arg2: denylist
                },
                text: ''
              )
            end
          end

          # Verify that claim alias lookup has aliases defined only once
          rule(:claim_aliases) do
            claims = values[:claim_aliases].to_s.split(',').map{|s| s.split(':').map(&:strip)}.map(&:first)
            if (duplicate = claims.detect { |claim| claims.count(claim) > 1 })
              key.failure(
                exception: Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError,
                text: '',
                args: {
                  arg1: 'annotation name',
                  arg2: duplicate
                }
              )
            end
          end

          # Verify that claim alias lookup has target defined only once
          rule(:claim_aliases) do
            claims = values[:claim_aliases].to_s.split(',').map{|s| s.split(':').map(&:strip)}.map(&:last)
            if (duplicate = claims.detect { |claim| claims.count(claim) > 1 })
              key.failure(
                exception: Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError,
                text: '',
                args: {
                  arg1: 'claim name',
                  arg2: duplicate
                }
              )
            end
          end

          # Ensure claims has only one `:` in it
          rule(:claim_aliases) do
            if (bad_claim = values[:claim_aliases].to_s.split(',').find { |item| item.count(':') != 1 })
              key.failure(
                exception: Errors::Authentication::AuthnJwt::ClaimAliasNameInvalidCharacter,
                text: bad_claim
              )
            end
          end

          # Check for "/" in claim keys
          rule(:claim_aliases) do
            claims = values[:claim_aliases].to_s.split(',').map{|s| s.split(':').map(&:strip)}.map(&:first)
            claims.flatten.each do |claim|
              if claim.match(/\//)
                key.failure(
                  exception: Errors::Authentication::AuthnJwt::ClaimAliasNameInvalidCharacter,
                  text: claim
                )
              end
            end
          end

          # Check for invalid characters in keys
          rule(:claim_aliases) do
            claims = values[:claim_aliases].to_s.split(',').map{|s| s.split(':').map(&:strip)}.map(&:first)
            if (bad_claim = claims.find { |claim| claim.count('a-zA-Z0-9\-_\.') != claim.length })
              key.failure(
                exception: Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName,
                args: {
                  arg1: bad_claim,
                  arg2: '[a-zA-Z0-9\-_\.]+'
                },
                text: ''
              )
            end
          end

          # Check for invalid characters in values
          rule(:claim_aliases) do
            claims = values[:claim_aliases].to_s.split(',').map{|s| s.split(':').map(&:strip)}.map(&:last)
            if (bad_value = claims.find { |claim| claim.count('a-zA-Z0-9\/\-_\.') != claim.length })
              key.failure(
                exception: Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName,
                text: '',
                args: {
                  arg1: bad_value,
                  arg2: '[a-zA-Z0-9\/\-_\.]+'
                }
              )
            end
          end

          rule(:claim_aliases) do
            denylist = %w[iss exp nbf iat jti aud]
            if (bad_item = (values[:claim_aliases].to_s.split(',').map{|s| s.split(':').map(&:strip)}.flatten & denylist).first)
              key.failure(
                exception: Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList,
                text: '',
                args: {
                  arg1: bad_item,
                  arg2: denylist
                }
              )
            end
          end

          # If using public-keys, issuer is required
          rule(:public_keys, :issuer, :account, :service_id) do
            if values[:public_keys].present? && values[:issuer].empty?
              key.failure(
                exception: Errors::Conjur::RequiredSecretMissing,
                text: "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/issuer"
              )
            end
          end
        end
      end
    end
  end
end
