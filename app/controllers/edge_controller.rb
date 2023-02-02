# frozen_string_literal: true

class EdgeController < RestController

  def all_secrets
    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
      .slice(*allowed_params).to_h.symbolize_keys
    begin
      #scope = Resource.visible_to(current_user).search(options)
      #scope = Resource.visible_to(current_user).search
      offset = options[:offset]
      limit = options[:limit]
      scope = Resource.where(:resource_id.like("conjur:variable:data%"))
      scope = scope.order(:resource_id).limit(
        (limit || 1000).to_i,
        (offset || 0).to_i
      )
    rescue ApplicationController::Forbidden
      raise
    rescue ArgumentError => e
      raise ApplicationController::UnprocessableEntity, e.message
    end
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
    render(json: results)
  end

  def all_hosts
    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    offset = options[:offset]
    limit = options[:limit]
    scope = Role.where(:role_id.like("conjur:host:data%"))
    scope = scope.order(:role_id).limit(
      (limit || 1000).to_i,
      (offset || 0).to_i
    )
    results = []
    hosts = scope.eager(:credentials).all
    hosts.each do |host|
      hostToReturn = {}
      hostToReturn[:id] = host[:role_id]
      hostToReturn[:api_key] =host.api_key
      hostToReturn[:memberships] =host.all_roles.all.select{|h| h[:role_id] != (host[:role_id])}
      results  << hostToReturn
    end
    render(json: results)
  end
end
