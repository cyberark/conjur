# frozen_string_literal: true

# Provides the installed authenticator status for the Conjur instance
module Authenticators
  private 

  def installed_authenticators
    @installed_authenticators ||= ::Authentication::InstalledAuthenticators.authenticators(ENV)
  end

  def installed_login_authenticators
    @installed_login_authenticators ||= ::Authentication::InstalledAuthenticators.login_authenticators(ENV)
  end

  def configured_authenticators
    @configured_authenticators ||= ::Authentication::InstalledAuthenticators.configured_authenticators()
  end

  def enabled_authenticators
    ::Authentication::InstalledAuthenticators.enabled_authenticators(ENV)
  end
end
