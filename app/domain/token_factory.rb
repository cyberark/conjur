# frozen_string_literal: true

require 'date'

class TokenFactory < Dry::Struct

  NoSigningKey = ::Util::ErrorClass.new(
    "Signing key not found for account '{0}'")

  attribute :slosilo, ::Types::Any.default{ Slosilo }

  MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION = 5.hours
  MINIMUM_AUTHENTICATION_TOKEN_EXPIRATION = 0

  def signing_key(account)
    slosilo["authn:#{account}".to_sym] || raise(NoSigningKey, account)
  end

  def signed_token(account:,
                   username:,
                   host_ttl: Rails.application.config.conjur_config.host_authorization_token_ttl,
                   user_ttl: Rails.application.config.conjur_config.user_authorization_token_ttl)

    if username.starts_with?('host/')
      offset = offset(ttl: host_ttl)
      hostname = username.split('/')[1..-1].join('/')
      role = Role["#{account}:host:#{hostname}"]
    else
      offset = offset(ttl: user_ttl)
      role = Role["#{account}:user:#{username}"]
    end

    raise 'Only hosts and users can use authorization tokens' unless role.present?

    issue_jwt(role: role, expires_in: offset)
  end

  def issue_jwt(role:, expires_in:)
    now = Time.now.to_i
    # binding.pry
    signing_key = signing_key(role.account)
    claims = {
      sub: role.role_id,
      exp: now + expires_in,
      nbf: now,
      iat: now,
      iss: 'cyberark/conjur'
    }
    claims[:restricted_to] = role.restricted_to.split(',').map(&:strip) unless role.restricted_to.blank?
    # Add signing key to headers so we can descern which account was used to sign the token
    JWT.encode(claims, signing_key.key, 'RS256', x5t: signing_key.fingerprint)
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
end
