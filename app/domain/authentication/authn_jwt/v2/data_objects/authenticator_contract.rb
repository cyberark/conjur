# frozen_string_literal: true

require 'json'
module Authentication
  module AuthnJwt
    module V2
      module DataObjects

        # This class handles all validation for the JWT authenticator. This contract
        # is executed against the data gleaned from Conjur variables when the authenicator
        # is loaded via the AuthenticatorRepository.

        # As the JWT authenticator is highly flexible and as a result, there are
        # a large number of potental "healthy" or "unhealthy" states.
        # rubocop:disable Metrics/ClassLength
        class AuthenticatorContract < Dry::Validation::Contract
          option :utils

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

          AUTHENTICATION_MECHANISMS = %i[jwks_uri provider_uri public_keys]

          # Verify that only one of `jwks-uri`, `public-keys`, and `provider-uri` are set
          rule(:jwks_uri, :public_keys, :provider_uri) do
            if AUTHENTICATION_MECHANISMS.select { |key| values[key].present? }.count > 1
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::InvalidSigningKeySettings.new(
                  'jwks-uri and provider-uri cannot be defined simultaneously'
                )
              )
            end
          end

          # Verify that `issuer` has a secret value set if the variable is present
          rule(:issuer, :account, :service_id) do
            variable_empty?(key: key, values: values, variable: 'issuer')
          end

          # Verify that `claim_aliases` has a secret value set if variable is present
          rule(:claim_aliases, :account, :service_id) do
            variable_empty?(key: key, values: values, variable: 'claim-aliases')
          end

          # Verify that `provider_uri` has a secret value set if variable is present
          rule(:provider_uri, :service_id, :account) do
            variable_empty?(key: key, values: values, variable: 'provider-uri')
          end

          # Verify that `jwks-uri`, `public-keys`, or `provider-uri` has a secret value set if a variable exists
          rule(:jwks_uri, :public_keys, :provider_uri, :account, :service_id) do
            empty_variables = AUTHENTICATION_MECHANISMS.select {|key, _| values[key] == '' && !values[key].nil? }
            if empty_variables.count == 1
              # Performing this insanity to match current functionality :P
              error = if empty_variables.first == :provider_uri
                Errors::Authentication::AuthnJwt::InvalidSigningKeySettings.new(
                  'Failed to find a JWT decode option. Either `jwks-uri` or `public-keys` variable must be set.'
                )
              else
                Errors::Conjur::RequiredSecretMissing.new(
                  "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/#{empty_variables.first.to_s.dasherize}"
                )
              end
              utils.failed_response(key: key, error: error)
            end
          end

          # Verify that a variable has been created for one of: `jwks-uri`, `public-keys`, or `provider-uri`
          rule(:jwks_uri, :public_keys, :provider_uri) do

            if AUTHENTICATION_MECHANISMS.all? { |item| values[item].nil? }
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::InvalidSigningKeySettings.new(
                  'One of the following must be defined: jwks-uri, public-keys, or provider-uri'
                )
              )
            end
          end

          # Verify that a variable has been set for one of: `jwks-uri`, `public-keys`, or `provider-uri`
          rule(:jwks_uri, :public_keys, :provider_uri) do
            if AUTHENTICATION_MECHANISMS.all? { |item| values[item].blank? }
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::InvalidSigningKeySettings.new(
                  'Failed to find a JWT decode option. Either `jwks-uri` or `public-keys` variable must be set'
                )
              )
            end
          end

          # Verify that `token_app_property` has a secret value set if the variable is present
          rule(:token_app_property, :account, :service_id) do
            variable_empty?(key: key, values: values, variable: 'token-app-property')
          end

          # Verify that `token_app_property` includes only valid characters
          rule(:token_app_property) do
            unless values[:token_app_property].to_s.count('a-zA-Z0-9\/\-_\.') == values[:token_app_property].to_s.length
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::InvalidTokenAppPropertyValue.new(
                  "token-app-property can only contain alpha-numeric characters, '-', '_', '/', and '.'"
                )
              )
            end
          end

          # Verify that `token_app_property` does not include double slashes
          rule(:token_app_property) do
            if values[:token_app_property].to_s.match(/\/\//)
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::InvalidTokenAppPropertyValue.new(
                  "token-app-property includes `//`"
                )
              )
            end
          end

          # Verify that `audience` has a secret value set if variable is present
          rule(:audience, :service_id, :account) do
            variable_empty?(key: key, values: values, variable: 'audience')
          end

          # Verify that `identity_path` has a secret value set if variable is present
          rule(:identity_path, :service_id, :account) do
            variable_empty?(key: key, values: values, variable: 'identity-path')
          end

          # Verify that `enforced_claims` has a secret value set if variable is present
          rule(:enforced_claims, :service_id, :account) do
            variable_empty?(key: key, values: values, variable: 'enforced-claims')
          end

          # Verify that claim values contain only "allowed" characters (alpha-numeric, plus: "-", "_", "/", ".")
          rule(:enforced_claims) do
            values[:enforced_claims].to_s.split(',').map(&:strip).each do |claim|
              next if claim.count('a-zA-Z0-9\/\-_\.') == claim.length

              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName.new(claim, "[a-zA-Z0-9\/\-_\.]+")
              )
            end
          end

          # Verify that there are no reserved claims in the enforced claims list
          rule(:enforced_claims) do
            denylist = %w[iss exp nbf iat jti aud]
            (values[:enforced_claims].to_s.split(',').map(&:strip) & denylist).each do |claim|
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList.new(claim, denylist)
              )
            end
          end

          # Verify that claim alias lookup has aliases defined only once
          rule(:claim_aliases) do
            claims = claim_as_array(values[:claim_aliases])
            if (duplicate = claims.detect { |claim| claims.count(claim) > 1 })
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError.new('annotation name', duplicate)
              )
            end
          end

          # Verify that claim alias lookup has target defined only once
          rule(:claim_aliases) do
            claims = values[:claim_aliases].to_s.split(',').map{|s| s.split(':').map(&:strip)}.map(&:last)
            if (duplicate = claims.detect { |claim| claims.count(claim) > 1 })
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::ClaimAliasDuplicationError.new('claim name', duplicate)
              )
            end
          end

          # Ensure claims has only one `:` in it
          rule(:claim_aliases) do
            if (bad_claim = values[:claim_aliases].to_s.split(',').find { |item| item.count(':') != 1 })
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::ClaimAliasNameInvalidCharacter.new(bad_claim)
              )
            end
          end

          # Check for "/" in claim keys
          rule(:claim_aliases) do
            claims = claim_as_array(values[:claim_aliases])
            claims.flatten.each do |claim|
              next unless claim.match(%r{/})

              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::ClaimAliasNameInvalidCharacter.new(claim)
              )
            end
          end

          def with_invalid_characters?(regex:, items:)
            items.find { |item| item.count(regex) != item.length }
          end


          # Check for invalid characters in keys
          rule(:claim_aliases) do
            claims = claim_as_array(values[:claim_aliases])
            if (bad_claim = with_invalid_characters?(regex: 'a-zA-Z0-9\-_\.', items: claims))
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName.new(bad_claim, '[a-zA-Z0-9\-_\.]+')
              )
            end
          end

          # Check for invalid characters in values
          rule(:claim_aliases) do
            claims = claim_as_array(values[:claim_aliases]) #.to_s.split(',').map{|s| s.split(':').map(&:strip)}.map(&:last)
            if (bad_value = with_invalid_characters?(regex: 'a-zA-Z0-9\/\-_\.', items: claims))
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::FailedToValidateClaimForbiddenClaimName.new(bad_value, "[a-zA-Z0-9\/\-_\.]+")
              )
            end
          end

          # check for claim aliases in keys or values
          rule(:claim_aliases) do
            denylist = %w[iss exp nbf iat jti aud]
            if (bad_item = (values[:claim_aliases].to_s.split(',').map{|s| s.split(':').map(&:strip)}.flatten & denylist).first)
              utils.failed_response(
                key: key,
                error: Errors::Authentication::AuthnJwt::FailedToValidateClaimClaimNameInDenyList.new(bad_item, denylist))
            end
          end

          # If using public-keys, issuer is required
          rule(:public_keys, :issuer, :account, :service_id) do
            if values[:public_keys].present? && values[:issuer].blank?
              utils.failed_response(
                key: key,
                error: Errors::Conjur::RequiredSecretMissing.new(
                  "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/issuer"
                )
              )
            end
          end

          # Ensure public keys value is valid JSON
          rule(:public_keys) do
            begin
              if values[:public_keys].present?
                JSON.parse(values[:public_keys])
              end
            rescue JSON::ParserError
              utils.failed_response(
                key: key,
                error: Errors::Conjur::MalformedJson.new(values[:public_keys])
              )
            end
          end

          # Ensure 'type' and 'value' keys exist, and type is equal to 'jwks'
          rule(:public_keys) do
            if values[:public_keys].present?
              begin
                json = JSON.parse(values[:public_keys])
                unless json.key?('value') && json.key?('type') && json['type'] == 'jwks'
                  utils.failed_response(
                    key: key,
                    error: Errors::Authentication::AuthnJwt::InvalidPublicKeys.new(
                      "Type can't be blank, Value can't be blank, and Type '' is not a valid public-keys type. Valid types are: jwks"
                    )
                  )
                end
              # Need to catch JSON parse exceptions because these rules are cumulative
              rescue JSON::ParserError
                nil
              end
            end
          end

          # Ensure public keys has a "keys" value that is an array
          rule(:public_keys) do
            if values[:public_keys].present?
              begin
                json = JSON.parse(values[:public_keys])
                unless json.key?('value') && json['value'].is_a?(Hash) && json['value'].key?('keys') && json['value']['keys'].is_a?(Array) && json['value']['keys'].count > 0
                  utils.failed_response(
                    key: key,
                    error: Errors::Authentication::AuthnJwt::InvalidPublicKeys.new(
                      "Value must include the name/value pair 'keys', which is an array of valid JWKS public keys"
                    )
                  )
                end
              # Need to catch JSON parse exceptions because these rules are cumulative
              rescue JSON::ParserError
                nil
              end
            end
          end

          # Verify that `ca_cert` has a secret value set if the variable is present
          rule(:ca_cert, :account, :service_id) do
            variable_empty?(key: key, values: values, variable: 'ca-cert')
          end

          def claim_as_array(claim)
            claim.to_s.split(',').map{|s| s.split(':').map(&:strip)}.map(&:first)
          end

          def variable_empty?(key:, values:, variable:)
            return unless values[variable.underscore.to_sym] == ''

            utils.failed_response(
              key: key,
              error: Errors::Conjur::RequiredSecretMissing.new(
                "#{values[:account]}:variable:conjur/authn-jwt/#{values[:service_id]}/#{variable}"
              )
            )
          end
        end
      end
    end
  end
end
