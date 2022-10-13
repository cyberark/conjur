# frozen_string_literal: true

require 'date'

class TokenFactory < Dry::Struct

  NoSigningKey = ::Util::ErrorClass.new(
    "Signing key not found for account '{0}'")

  attribute :slosilo, ::Types::Any.default{ Slosilo }

  MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION = 5.hours

  def signing_key(account)
    slosilo["authn:#{account}".to_sym] || raise(NoSigningKey, account)
  end

  def signed_token(account:,
                   username:,
                   additional_claims: {},
                   host_ttl: Rails.application.config.conjur_config.host_authorization_token_ttl,
                   user_ttl: Rails.application.config.conjur_config.user_authorization_token_ttl)

    claims = additional_claims.merge({
      sub: username,
      exp: Time.now + offset(
        ttl: username.starts_with?('host/') ? host_ttl : user_ttl
      )
    })
    signing_key(account).issue_jwt(**claims)
  end

  def offset(ttl:)
    return ttl.to_i if ttl.to_i < MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION

    MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION
  end

end
