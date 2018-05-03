class Authenticate
  attr_accessor :basic_user, :authenticated_role, :selected_role

  def basic_user?
    !!basic_user
  end

  # Whether an authenticated user is available.
  def authenticated?
    !!authenticated_role
  end

  def apply_to_role
    selected_role || authenticated_role
  end

  # Determines whether the authenticated user is managing itself.
  def self?
    selected_role.nil? || selected_role == authenticated_role
  end
end
