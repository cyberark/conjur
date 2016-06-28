class Authentication
  attr_accessor :token_user, :basic_user, :user_id
  
  # Whether an authenticated user is available.
  def authenticated?
    !authenticated_username.nil?
  end
  
  # Login name of the authenticated user.
  def authenticated_username
    basic_user || ( token_user ? token_user.login : nil )
  end
  
  # Account name of the authenticated user.
  def authenticated_account
    token_user ? token_user.account : my_account
  end
  
  # Lookup the database user, defaulting to the authenticated_username.
  def database_user
    @user ||= AuthnUser[user_id || authenticated_username]
  end
  
  # The account name of this database.
  def my_account
    User.account
  end
  
  # Determines whether the authenticated user is managing itself.
  def self?
    user_id.nil? || user_id == authenticated_username && my_account == authenticated_account
  end
end
