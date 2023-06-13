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

    key = Account.token_key(account, "host")
    if key.nil?
      raise RecordNotFound, "No Slosilo key in DB"
    end

    private_key = key.to_der.unpack("H*")[0]
    fingerprint = key.fingerprint
    variable_to_return = {}
    variable_to_return[:privateKey] = private_key
    variable_to_return[:fingerprint] = fingerprint
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("slosilo_keys"))
    render(json: { "slosiloKeys": [variable_to_return] })
  end

  # Return all secrets within offset-limit frame. Default is 0-1000
  def all_secrets
    logger.info(LogMessages::Endpoints::EndpointRequested.new("all_secrets"))

    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    begin
      verify_edge_host(options)

      scope = Resource.where(:resource_id.like(options[:account] + ":variable:data/%"))
      if params[:count] == 'true'
        sumItems = scope.count('*'.lit)
      else
        offset = options[:offset] || "0"
        limit = options[:limit] || "1000"
        validate_scope(limit, offset)
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
      failed = []
      accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
      if accepts_base64
        response.set_header("Content-Encoding", "base64")
      end

      variables = build_variables_map(limit, offset, options)

      variables.each do |id, variable|
        variableToReturn = {}
        variableToReturn[:id] = id
        variableToReturn[:owner] = variable[:owner_id]
        variableToReturn[:permissions] = []
        Sequel::Model.db.fetch("SELECT * from permissions where resource_id='" + id + "' AND privilege = 'execute'") do |row|
          permission = {}
          permission[:privilege] = row[:privilege]
          permission[:resource] = row[:resource_id]
          permission[:role] = row[:role_id]
          permission[:policy] = row[:policy_id]
          variableToReturn[:permissions].append(permission)
        end
        secret_value = Slosilo::EncryptedAttributes.decrypt(variable[:value], aad: id)
        variableToReturn[:value] = accepts_base64 ? Base64.strict_encode64(secret_value) : secret_value
        variableToReturn[:version] = variable[:version]
        variableToReturn[:versions] = []
        value = {
          "version": variableToReturn[:version],
          "value": variableToReturn[:value]
        }
        variableToReturn[:versions] << value
        begin
          JSON.generate(variableToReturn)
          results << variableToReturn
        rescue => e
          failed << { "id": id }
        end

      end
      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfullyWithLimitAndOffset.new(
        "all_secrets",
        limit,
        offset
      ))
      if (failed.size > 0)
        logger.info(LogMessages::Util::FailedSerializationOfResources.new(
          "all_secrets",
          limit,
          offset,
          failed.size,
          failed.first
        ))
      end
      render(json: { "secrets": results, "failed": failed })
    end
  end

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
      hosts = scope.eager(:credentials).all
      hosts.each do |host|
        hostToReturn = {}
        hostToReturn[:id] = host[:role_id]
        salt = OpenSSL::Random.random_bytes(32)
        hostToReturn[:api_key] = Base64.strict_encode64(hmac_api_key(host.api_key, salt))
        hostToReturn[:salt] = Base64.strict_encode64(salt)
        hostToReturn[:memberships] = host.all_roles.all.select { |h| h[:role_id] != (host[:role_id]) }
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

  def all_edges
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    verify_conjur_admins(options)
    render(json: Edge.all.map{|edge|
      {name: edge.name, ip: edge.ip, last_sync: edge.last_sync,
       version:edge.version, installation_date: edge.installation_date}})
  end

  def report_edge_data
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    verify_edge_host(options)
    data = JSON.parse(request.body.read)
    record_edge_access(current_user.role_id, data)
    #TODO: print to log other data
  end

  private

  def build_variables_map(limit, offset, options)
    variables = {}

    Sequel::Model.db.fetch("SELECT * FROM secrets JOIN (SELECT resource_id, owner_id FROM resources WHERE (resource_id LIKE '" + options[:account] + ":variable:data/%') ORDER BY resource_id LIMIT " + limit.to_s + " OFFSET " + offset.to_s + ") AS res ON (res.resource_id = secrets.resource_id)") do |row|
      if variables.key?(row[:resource_id])
        if row[:version] > variables[row[:resource_id]][:version]
          variables[row[:resource_id]] = row
        end
      else
        variables[row[:resource_id]] = row
      end
    end
    variables
  end

  def validate_scope(limit, offset)
    if offset || limit
      # 'limit' must be an integer greater than 0 and less than 2000 if given
      if limit && (!numeric?(limit) || limit.to_i <= 0 || limit.to_i > 2000)
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

  def verify_conjur_admins(options)
    admins_group = Role[options[:account] + ':group:Conjur_Cloud_Admins'] #TODO: get conjur admins group from CES
    unless admins_group&.ancestor_of?(current_user)
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Current user is: #{current_user}. should be member of #{admins_group}"
        )
      )
      raise Forbidden
    end
  end

  def numeric? val
    val == val.to_i.to_s
  end

  def record_edge_access(host_name, data)
    edge_record = Edge.get_by_hostname(host_name) || raise(RecordNotFound.new(host_name, message: "Edge for host #{host_name} not found"))
    edge_record.ip = request.ip
    edge_record.version = get_value(data, "edge_version")
    sync_time = get_value(data, "edge_statistics.last_synch_time")
    if sync_time
      edge_record.last_sync = sync_time
      edge_record.installation_date = sync_time unless edge_record.installation_date
    end
    edge_record.platform = get_value(data, "edge_container_type")

    edge_record.save
  end

  def get_value(data, key)
    key_parts = key.split('.')
    current_value = data

    key_parts.each do |key_part|
      raise BadRequest unless current_value.is_a?(Hash) && current_value.key?(key_part)
      current_value = current_value[key_part]
    end

    current_value
  end
end
