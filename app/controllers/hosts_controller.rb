# frozen_string_literal: true

class HostsController < RestController
  include HostValidator
  def edge_hosts
    logger.info(LogMessages::Endpoints::EndpointRequestedByUser.new("edge-hosts", Role.username_from_roleid(current_user.role_id)))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    begin
      _verify_host(options)
    rescue ApplicationController::Forbidden
      raise
    end
    results = []
    hosts = Role.where(:role_id.like(options[:account]+":host:edge/%"))
    hosts.each do |host|
      id = host[:role_id]
      next unless is_role_member_of_group(options[:account], id, ":group:edge/edge-hosts")
      host_name = id.split('/').last
      host_to_return = {}
      host_to_return[:id] = id
      host_to_return[:name] = host_name
      results << host_to_return
    end
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge-hosts"))
    render(json:{"hosts": results})
  end

  def _verify_host(options)
    account = options[:account]
    validate_conjur_account(account)
    validate_conjur_admin_group(account)
  end
end
