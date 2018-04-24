require 'types'

class TokenFactory < Dry::Struct

  attribute :slosilo, Types::Any.default(Slosilo)

  def signing_key(account)
    slosilo["authn:#{account}".to_sym] or
      raise Unauthorized, "Signing key not found for account '#{account}'"
  end
    
  def signed_token(account:, username:)
    signing_key(account).issue_jwt(sub: username)
  end

end
