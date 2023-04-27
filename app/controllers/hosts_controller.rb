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
      host_to_return = {}
      id = host[:role_id]
      next unless is_role_member_of_group(options[:account], id, ":group:edge/edge-hosts")
      host_name = id.split('/').last
      host_to_return[:id] = id
      host_to_return[:name] = host_name
      results << host_to_return
    end
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge-hosts"))
    render(json:{"hosts": results})
  end

  def host_credential
    logger.info(LogMessages::Endpoints::EndpointRequested.new("host", Role.username_from_roleid(current_user.role_id)))
    allowed_params = %i[account host_name]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    begin
      _verify_host(options)
      host = Credentials.where(:role_id.like("%/"+options[:host_name])).all
      _validate_edge_host_name(options[:account], host)
    rescue ApplicationController::Forbidden
      raise
    rescue ArgumentError => e
      raise ApplicationController::RecordNotFound, e.message
    end

    api_key = host[0].api_key
    host_id = host[0][:role_id]
    result = Base64.strict_encode64(host_id+":"+api_key)
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("host"))
    response.set_header("Content-Encoding", "base64")
    render(plain: result, content_type: "text/plain")

  end

  def _validate_edge_host_name(account, host)
    unless host.length == 1
      raise ArgumentError, "Edge host not found"
    end
    host_id = host[0][:role_id]
    unless is_role_member_of_group(account, host_id, ':group:edge/edge-hosts')
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Current host is not a member of edge host group"
        )
      )
      raise ApplicationController::Forbidden
    end
  end

  def _verify_host(options)
    account = options[:account]
    validate_conjur_account(account)
    validate_conjur_admin_group(account)
  end
end
