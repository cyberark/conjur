# frozen_string_literal: true

require 'date'

class TokenFactory < Dry::Struct

  NoSigningKey = ::Util::ErrorClass.new(
    "Signing key not found for account '{0}'")

  attribute :slosilo, ::Types::Any.default{ Slosilo }

  def signing_key(account)
    slosilo["authn:#{account}".to_sym] || raise(NoSigningKey, account)
  end

  def signed_host_key(account:, username:)
    exp_t = Time.now + Rails.application.config.conjur_config.host_authorization_token_ttl.to_i
    signing_key(account).issue_jwt(sub: username, exp: exp_t)
  end

  def signed_token(account:, username:)
    if username.starts_with?('host/')
      signed_host_key(account: account, username: username)
    else
      exp_t = Time.now + Rails.application.config.conjur_config.user_authorization_token_ttl.to_i
      signing_key(account).issue_jwt(sub: username, exp: exp_t)
    end
  end

end
