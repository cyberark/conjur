# frozen_string_literal: true
require 'securerandom'
require 'sequel'

class Edge < Sequel::Model

  EDGE_HOST_PATTERN = "ACCOUNT:host:edge/edge-IDENTIFIER/edge-host-IDENTIFIER"
  EDGE_INSTALLER_HOST_PATTERN = "ACCOUNT:host:edge/edge-installer-IDENTIFIER/edge-installer-host-IDENTIFIER"
    class << self

    def new_edge(**values)
      raise ArgumentError, 'Edge name is not provided' unless values[:name]
      values[:id] ||= SecureRandom.uuid

      begin
        Edge.insert(**values)
      rescue
        raise(Exceptions::RecordExists.new(values[:name], message: "Edge name #{values[:name] } already exists"))
      end
    end

    def get_by_hostname(hostname)
      Edge.where(id: hostname_to_id(hostname)).first || raise(Exceptions::RecordNotFound.new(hostname,
                                                                message: "Edge for host #{hostname} not found"))
    end

    def hostname_to_id(hostname)
      regex = Regexp.new(EDGE_HOST_PATTERN.sub("ACCOUNT", '\w+').gsub("IDENTIFIER","(.+)"))
      hostname.match(regex)&.captures&.first
    end

  end

  def record_edge_access(data, ip)
    self.ip = ip
    self.version = data['edge_version'] if data['edge_version']
    sync_time = Time.at(data['edge_statistics']['last_synch_time']) # This field is required
    self.last_sync = sync_time if sync_time.to_i > 0
    self.platform = data['edge_container_type'] if data['edge_container_type']

    self.save
  end

  def get_edge_host_name(account)
    EDGE_HOST_PATTERN.sub("ACCOUNT", account).gsub("IDENTIFIER", self.id)
  end

  def get_edge_installer_host_name(account)
    EDGE_INSTALLER_HOST_PATTERN.sub("ACCOUNT", account).gsub("IDENTIFIER", self.id)
  end

  def get_installer_token(account, request)
    installer_host_full_name = self.get_edge_installer_host_name(account)
    installer_name = Role.username_from_roleid(installer_host_full_name)
    installer_role = Role[installer_host_full_name]
    # Authenticate
    auth_input = Authentication::AuthenticatorInput.new(
      authenticator_name: Authentication::Common.default_authenticator_name,
      service_id: nil,
      account: account,
      username: installer_name,
      credentials: installer_role.api_key,
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
