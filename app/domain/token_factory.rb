# frozen_string_literal: true

require 'date'

class TokenFactory < Dry::Struct

  NoSigningKey = ::Util::ErrorClass.new(
    "Signing key not found for account '{0}'")

  attribute :slosilo, ::Types::Any.default{ Slosilo }

  MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION = 5.hours
  MINIMUM_AUTHENTICATION_TOKEN_EXPIRATION = 0

  def signing_key(username, account)
    sloislo_key = host?(username) ? Account.token_key(account, "host") : Account.token_key(account, "user")
    sloislo_key || raise(NoSigningKey, Account.token_id(account, host?(username) ? "host" : "user"))
  end
  
  def signed_token(account:,
                   username:,
                   host_ttl: Rails.application.config.conjur_config.host_authorization_token_ttl,
                   user_ttl: Rails.application.config.conjur_config.user_authorization_token_ttl)
    signing_key(username, account).issue_jwt(
      sub: username,
      exp: Time.now + offset(
        ttl: host?(username) ? host_ttl : user_ttl
      )
    )
  end

  def offset(ttl:)
    offset = parse_ttl(ttl: ttl)
    return MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION if offset > MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION
    return MINIMUM_AUTHENTICATION_TOKEN_EXPIRATION if offset < MINIMUM_AUTHENTICATION_TOKEN_EXPIRATION

    offset
  end

  def parse_ttl(ttl:)
    # If TTL is an integer, return it
    return ttl.to_i if ttl.to_i.to_s == ttl.to_s
    # Attempt to coerce a string into integer
    ttl.to_s.to_i
  end
  
  def host?(username)
    username.start_with?('host/')
  end
end
