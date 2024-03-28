# frozen_string_literal: true

module HostAuthentication
  def get_access_token(account, host_full_id, request)
    host_name = Role.username_from_roleid(host_full_id)
    host_role = Role[host_full_id]
    # Authenticate
    auth_input = Authentication::AuthenticatorInput.new(
      authenticator_name: Authentication::Common.default_authenticator_name,
      service_id: nil,
      account: account,
      username: host_name,
      credentials: host_role.api_key,
      client_ip: request.ip,
      request: request
    )
    installer_token = new_authenticate.call(
      authenticator_input: auth_input,
      authenticators: Authentication::InstalledAuthenticators.authenticators(ENV),
      enabled_authenticators: Authentication::InstalledAuthenticators.enabled_authenticators_str
    )
    Base64.strict_encode64(installer_token.to_json)
  end

  private
  def new_authenticate
    Authentication::Authenticate.new
  end

end
