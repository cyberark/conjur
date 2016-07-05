class Authentication
  attr_accessor :token_user, :basic_user, :role_id
  
  # Whether an authenticated user is available.
  def authenticated?
    !authenticated_username.nil?
  end
  
  # Login name of the authenticated user.
  def authenticated_username
    basic_user || ( token_user ? token_user.login : nil )
  end
  
  def database_role
    @role ||= Role[Role.roleid_from_username(role_id || authenticated_username)]
  end
  
  # Account name of the authenticated user.
  def authenticated_account
    token_user ? token_user.account : default_account
  end

  # Determines whether the authenticated user is managing itself.
  def self?
    role_id.nil? || role_id == Role.roleid_from_username(authenticated_username)
  end
end
