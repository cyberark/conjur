module TokenGenerator
  extend ActiveSupport::Concern

  def signing_key
    Slosilo["authn:#{account}".to_sym] or raise Unauthorized, "No signing key is available for account '#{account}'"
  end
    
  def sign_token role
    signing_key.issue_jwt sub: Role.username_from_roleid(role.id)
  end

end
