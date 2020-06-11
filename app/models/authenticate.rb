# frozen_string_literal: true

class Authenticate
  attr_accessor :basic_user, :authenticated_role, :selected_role

  # TODO: See issue https://github.com/cyberark/conjur/issues/1608
  # :reek:NilCheck
  def basic_user?
    !basic_user.nil?
  end

  # Whether an authenticated user is available.
  # TODO: See issue https://github.com/cyberark/conjur/issues/1608
  # :reek:NilCheck
  def authenticated?
    !authenticated_role.nil?
  end

  def apply_to_role
    selected_role || authenticated_role
  end

  # Determines whether the authenticated user is managing itself.
  # TODO: See issue https://github.com/cyberark/conjur/issues/1608
  # :reek:NilCheck
  def self?
    selected_role.nil? || selected_role == authenticated_role
  end
end
