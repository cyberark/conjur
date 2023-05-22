# frozen_string_literal: true

class EdgeController < RestController
  include Cryptography

  def slosilo_keys
    logger.info(LogMessages::Endpoints::EndpointRequested.new("slosilo_keys"))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    begin
      verify_edge_host(options)
    rescue ApplicationController::Forbidden
      raise
    end
    account = options[:account]
    key_id = "authn:" + account

    key = Slosilo[key_id]
    if key.nil?
      raise RecordNotFound, "No Slosilo key in DB"
    end

    private_key = key.to_der.unpack("H*")[0]
    fingerprint = key.fingerprint
    variable_to_return = {}
    variable_to_return[:privateKey] = private_key
    variable_to_return[:fingerprint] = fingerprint
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("slosilo_keys"))
    render(json: {"slosiloKeys":[variable_to_return]})
  end

  def all_secrets
    logger.info(LogMessages::Endpoints::EndpointRequested.new("all_secrets"))

    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    begin
      verify_edge_host(options)
      scope = Resource.where(:resource_id.like(options[:account]+":variable:data/%"))
      if params[:count] == 'true'
        sumItems = scope.count('*'.lit)
      else
        offset = options[:offset]
        limit = options[:limit]
        validate_scope(limit, offset)
        scope = scope.order(:resource_id).limit(
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
      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("all_secrets:count"))
      render(json: results)
    else
      results = []
      variables = scope.eager(:permissions).eager(:secrets).all
      accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
      if accepts_base64
        response.set_header("Content-Encoding", "base64")
      end
      variables.each do |variable|
        variableToReturn = {}
        variableToReturn[:id] = variable[:resource_id]
        variableToReturn[:owner] = variable[:owner_id]
        variableToReturn[:permissions] =  variable.permissions.select{|h| h[:privilege].eql?('execute')}
        unless variable.last_secret.nil?
          variableToReturn[:version] = variable.last_secret.version
          secret_value = variable.last_secret.value
          variableToReturn[:value] =  accepts_base64 ? Base64.strict_encode64(secret_value) : secret_value
          variableToReturn[:versions] = []
          value = {
            "version": variableToReturn[:version],
            "value": variableToReturn[:value]
          }
          variableToReturn[:versions] << value
        end
        results  << variableToReturn
      end
      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("all_secrets"))
      render(json: {"secrets":results})
    end
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
        salt = OpenSSL::Random.random_bytes(32)
        hostToReturn[:api_key] = Base64.strict_encode64(hmac_api_key(host.api_key, salt))
        hostToReturn[:salt] = Base64.strict_encode64(salt)
        hostToReturn[:memberships] =host.all_roles.all.select{|h| h[:role_id] != (host[:role_id])}
        results  << hostToReturn
      end
      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("all_hosts"))
      render(json: {"hosts": results})
    end
  end


  private
  def validate_scope(limit, offset)
    if offset || limit
      # 'limit' must be an integer greater than 0 and less than 2000 if given
      if limit && (!numeric?(limit) || limit.to_i <= 0 || limit.to_i > 2000 )
        raise ArgumentError, "'limit' contains an invalid value. 'limit' must be a positive integer and less than 2000"
      end
      # 'offset' must be an integer greater than or equal to 0 if given
      if offset && (!numeric?(offset) || offset.to_i.negative?)
        raise ArgumentError, "'offset' contains an invalid value. 'offset' must be an integer greater than or equal to 0."
      end
    end
  end
  def verify_edge_host(options)
    msg = ""
    raise_excep = false

    if %w[conjur cucumber rspec].exclude?(options[:account])
      raise_excep = true
      msg = "Account is: #{options[:account]}. Should be one of the following: [conjur cucumber rspec]"
    elsif current_user.kind != 'host'
      raise_excep = true
      msg = "User kind is: #{current_user.kind}. Should be: 'host'"
    elsif current_user.role_id.exclude?("host:edge/edge")
      raise_excep = true
      msg = "Role is: #{current_user.role_id}. Should include: 'host:edge/edge'"
    else
      role = Role[options[:account] + ':group:edge/edge-hosts']
      unless role&.ancestor_of?(current_user)
        raise_excep = true
        msg = "Curren user is: #{current_user}. should be member of #{role}"
      end
    end

    if raise_excep
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          msg
        )
      )
      raise Forbidden
    end
  end

  def numeric? val
    val == val.to_i.to_s
  end
end
