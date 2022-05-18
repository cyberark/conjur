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
                   host_ttl: Rails.application.config.conjur_config.host_authorization_token_ttl,
                   user_ttl: Rails.application.config.conjur_config.user_authorization_token_ttl)
    offset = username.starts_with?('host/') ? host_ttl : user_ttl
    exp_t = get_token_expiration(offset)
    signing_key(account).issue_jwt(sub: username, exp: exp_t)
  end

  def get_token_expiration(offset)
    offset < MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION ? Time.now + offset : Time.now + MAXIMUM_AUTHENTICATION_TOKEN_EXPIRATION
  end

end
