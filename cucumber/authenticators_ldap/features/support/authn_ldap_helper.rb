# frozen_string_literal: true

# Utility methods for LDAP authenticator
#
require 'cucumber/_authenticators_common/features/support/authenticator_helpers'
module AuthnLdapHelper
  # Utility methods for LDAP authenticator
  include AuthenticatorHelpers

  def login_with_ldap(service_id:, account:, username:, password:)
    path = "#{conjur_hostname}/authn-ldap/#{service_id}/#{account}/login"
    get(path, user: username, password: password)
    @ldap_auth_key = response_body
  end

  def authenticate_with_ldap(service_id:, account:, username:, api_key:)
    path = "#{conjur_hostname}/authn-ldap/#{service_id}/#{account}/#{username}/authenticate"
    post(path, api_key)
  end

  def ldap_ca_certificate_value
    @ldap_ca_certificate_value ||= File.read('/ldap-certs/root.cert.pem')
  end

end

World(AuthnLdapHelper)
