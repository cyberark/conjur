# frozen_string_literal: true

class EdgeController < RestController

  def slosilo_keys
    url = "edge/slosilo_keys:account"
    Rails.logger.info(LogMessages::Conjur::UrlRequested.new(url))
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
    Rails.logger.info(LogMessages::Conjur::UrlFinishedSuccessfully.new(url))
    render(json: {"slosiloKeys":[variable_to_return]})
  end

  def all_secrets
    url = "edge/secrets:account"
    Rails.logger.info(LogMessages::Conjur::UrlRequested.new(url))

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
      Rails.logger.info(LogMessages::Conjur::UrlFinishedSuccessfully.new(url))
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
      Rails.logger.info(LogMessages::Conjur::UrlFinishedSuccessfully.new(url))
      render(json: {"secrets":results})
    end
  end

  def all_hosts
    url = "edge/hosts:account"
    Rails.logger.info(LogMessages::Conjur::UrlRequested.new(url))

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
      render(json: {"hosts": results})
    end

    Rails.logger.info(LogMessages::Conjur::UrlFinishedSuccessfully.new(url))
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
    unless %w[conjur cucumber rspec].include?(options[:account])
      Rails.logger.info(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Account is: #{options[:account]}. Should be one of the following: [conjur cucumber rspec]"
        ).message
      )
      raise Forbidden
    end

    unless current_user.kind == 'host'
      Rails.logger.info(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "User kind is: #{current_user.kind}. Should be: 'host'"
        )
      )
      raise Forbidden
    end

    unless current_user.role_id.include?("host:edge/edge")
      Rails.logger.info(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Role is: #{current_user.role_id}. Should include: 'host:edge/edge'"
        )
      )
      raise Forbidden
    end

    role = Role[options[:account] + ':group:edge/edge-hosts']
    unless role&.ancestor_of?(current_user)
      Rails.logger.info(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Curren user is not under #{role}"
        )
      )
      raise Forbidden
    end
  end


  def hmac_api_key(host, salt)
    pass = host.api_key
    iter = 20
    key_len = 16
    OpenSSL::KDF.pbkdf2_hmac(pass, salt: salt, iterations: iter, length: key_len, hash: "sha256")
  end

  def numeric? val
    val == val.to_i.to_s
  end
end
