class EdgeHostsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator

  def all_hosts
    logger.info(LogMessages::Endpoints::EndpointRequested.new("all_hosts"))

    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    begin
      verify_edge_host(options)
      scope = Role.where(:role_id.like(options[:account] + ":host:data/%"))
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
      roles_with_creds = scope.eager(:credentials)
      hosts = Role.roles_with_annotations(roles_with_creds).all
      hosts.each do |host|
        hostToReturn = {}
        hostToReturn[:id] = host[:role_id]
        salt = OpenSSL::Random.random_bytes(32)
        hostToReturn[:api_key] = Base64.strict_encode64(hmac_api_key(host.api_key, salt))
        hostToReturn[:salt] = Base64.strict_encode64(salt)
        hostToReturn[:memberships] = host.all_roles.all.select { |h| h[:role_id] != (host[:role_id]) }
        hostToReturn[:annotations] = host[:annotations] == "[null]" ? [] : JSON.parse(host[:annotations])
        results << hostToReturn
      end
      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfullyWithLimitAndOffset.new(
        "all_hosts",
        limit,
        offset
      ))
      render(json: { "hosts": results })
    end
  end

end