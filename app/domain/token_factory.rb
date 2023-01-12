# frozen_string_literal: true

require 'date'

class TokenFactory
  MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION = 5.hours
  MINIMUM_AUTHENTICATION_TOKEN_EXPIRATION = 30.seconds

  NoSigningKey = ::Util::ErrorClass.new(
    "Signing key not found for account '{0}'"
  )

  def initialize(
    slosilo: Slosilo,
    default_user_ttl: Rails.application.config.conjur_config.user_authorization_token_ttl,
    default_host_ttl: Rails.application.config.conjur_config.host_authorization_token_ttl
  )
    @slosilo = slosilo
    @default_user_ttl = default_user_ttl
    @default_host_ttl = default_host_ttl
  end

  # This method accepts both ttl and default ttl so that the ttl can be defined as a Conjur variable, but default
  def signed_token(account:, username:, ttl: 0, default_ttl: 480)
    signing_key(account).issue_jwt(
      sub: username,
      exp: Time.now + offset(ttl: get_ttl(ttl: ttl, default_ttl: default_ttl, is_host: username.starts_with?('host/')))
    )
  end

  # Methods below are intended to be private. They are kept public to simplify unit testing
  def slosilo
    Slosilo
  end

  def signing_key(account)
    slosilo["authn:#{account}".to_sym] || raise(NoSigningKey, account)
  end

  def get_ttl(ttl:, default_ttl:, is_host:)
    # If ttl is set (because it's defined as an authenticator variable, use that)
    return ttl.to_i unless ttl.to_i.zero?

    # If ttl is not set, fall back to defined configuration
    return @default_host_ttl.to_i if is_host && !@default_host_ttl.to_i.zero?
    return @default_user_ttl.to_i if !is_host && !@default_user_ttl.to_i.zero?

    # Else, return the default
    default_ttl.to_i
  end

  def offset(ttl:)
    return MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION if ttl > MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION
    return MINIMUM_AUTHENTICATION_TOKEN_EXPIRATION if ttl < MINIMUM_AUTHENTICATION_TOKEN_EXPIRATION

    ttl
  end
end
