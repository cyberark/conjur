# frozen_string_literal: true

class EdgeController < RestController

  def all_secrets
    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
      .slice(*allowed_params).to_h.symbolize_keys
    begin
      verify_edge_host(options)
      #scope = Resource.visible_to(current_user).search(options)
      #scope = Resource.visible_to(current_user).search
      offset = options[:offset]
      limit = options[:limit]
      scope = Resource.where(:resource_id.like(options[:account]+":variable:data%"))
      scope = scope.order(:resource_id).limit(
        (limit || 1000).to_i,
        (offset || 0).to_i
      )
    rescue ApplicationController::Forbidden
      raise
    rescue ArgumentError => e
      raise ApplicationController::UnprocessableEntity, e.message
    end

    if params[:count] == 'true'
      results = { count: scope.count('*'.lit) }
      render(json: results)
    else
      results = []
      variables = scope.eager(:permissions).eager(:secrets).all
      variables.each do |variable|
        variableToReturn = {}
        variableToReturn[:id] = variable[:resource_id]
        variableToReturn[:owner] = variable[:owner_id]
        variableToReturn[:permissions] =  variable.permissions.select{|h| h[:privilege].eql?('execute')}
        unless variable.last_secret.nil?
          variableToReturn[:version] = variable.last_secret.version
          variableToReturn[:value] = variable.last_secret.value
        end
        results  << variableToReturn
      end
      render(json: {"secrets":results})
    end
  end

  def all_hosts
    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    verify_edge_host(options)
    offset = options[:offset]
    limit = options[:limit]
    scope = Role.where(:role_id.like(options[:account]+":host:data%"))
    scope = scope.order(:role_id).limit(
      (limit || 1000).to_i,
      (offset || 0).to_i
    )
    if params[:count] == 'true'
      results = { count: scope.count('*'.lit) }
      render(json: results)
    else
      results = []
      hosts = scope.eager(:credentials).all
      hosts.each do |host|
        hostToReturn = {}
        hostToReturn[:id] = host[:role_id]
        hostToReturn[:api_key] =host.api_key
        hostToReturn[:memberships] =host.all_roles.all.select{|h| h[:role_id] != (host[:role_id])}
        results  << hostToReturn
      end
      render(json: {"hosts": results})
    end
  end

  private

  def verify_edge_host(options)
    raise Forbidden, 'Requestor is not a host' unless current_user.kind == 'host'
    role = Role[options[:account] + ':group:edge/edge-admins']
    raise Forbidden unless role && role.ancestor_of?(current_user)
  end
end
