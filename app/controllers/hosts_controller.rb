# frozen_string_literal: true

class HostsController < RestController
  include HostValidator
  include ValidateScope

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

  def all_hosts
    logger.info(LogMessages::Endpoints::EndpointRequested.new("all_hosts"))

    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    begin
      verify_edge_host(options)
      scope = Role.where(:role_id.like(options[:account]+":host:data/%"))
      if params[:count] == 'true'
        sumItems = scope.count('*'.lit)
      else
        offset = options[:offset]
        limit = options[:limit]
        validate_scope(limit, offset)
        scope = scope.order(:role_id).limit(
          (limit || 1000).to_i,
          (offset || 0).to_i
        )
      end
    rescue ApplicationController::Forbidden
      raise
    rescue ArgumentError => e
      raise ApplicationController::UnprocessableEntity, e.message
    end
    if params[:count] == 'true'
      results = { count: sumItems }
      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("all_hosts:count"))
      render(json: results)
    else
      results = []
      hosts = scope.eager(:credentials).all
      hosts.each do |host|
        hostToReturn = {}
        hostToReturn[:id] = host[:role_id]
        #salt = OpenSSL::Random.random_bytes(32)
        #hostToReturn[:api_key] = Base64.encode64(hmac_api_key(host, salt))
        hostToReturn[:api_key] = host.api_key
        #hostToReturn[:salt] = Base64.encode64(salt)
        hostToReturn[:memberships] =host.all_roles.all.select{|h| h[:role_id] != (host[:role_id])}
        results  << hostToReturn
      end
      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("all_hosts"))
      render(json: {"hosts": results})
    end
  end

  private

  def _verify_host(options)
    account = options[:account]
    validate_conjur_account(account)
    validate_conjur_admin_group(account)
  end

  def hmac_api_key(host, salt)
    pass = host.api_key
    iter = 20
    key_len = 16
    OpenSSL::KDF.pbkdf2_hmac(pass, salt: salt, iterations: iter, length: key_len, hash: "sha256")
  end
end

