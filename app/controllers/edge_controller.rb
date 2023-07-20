# frozen_string_literal: true

class EdgeController < RestController
  include Cryptography
  include EdgeValidator
  include AccountValidator
  include GroupMembershipValidator
  include BodyParser

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
    return_json = {}
    key_object = [get_key_object(key)]
    return_json[:slosiloKeys] = key_object

    prev_key = Account.token_key(account, "host", "previous")
    prev_key_obj = prev_key.nil? ? [] : [get_key_object(prev_key)]
    return_json[:previousSlosiloKeys] = prev_key_obj

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("slosilo_keys"))
    render(json: return_json)
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
    logger.info(LogMessages::Endpoints::EndpointRequested.new("edge/edges"))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    validate_conjur_admin_group(options[:account])
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge/edges"))
    render(json: Edge.all.map{|edge|
      {name: edge.name, ip: edge.ip, last_sync: edge.last_sync.to_i,
       version:edge.version, installation_date: edge.installation_date.to_i, platform: edge.platform}})
  end

  def report_edge_data
    logger.info(LogMessages::Endpoints::EndpointRequested.new('edge/data'))
    allowed_params = %i[account data_type]
    url_params = params.permit(*allowed_params)
    verify_edge_host(url_params)
    data_handlers = {'install' => EdgeLogic::DataHandlers::InstallHandler , 'ongoing' => EdgeLogic::DataHandlers::OngoingHandler}
    handler = data_handlers[url_params[:data_type]]
    raise BadRequest unless handler

    handler.new(logger).call(params, current_user.role_id, request.ip)

    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge/data"))
  end

  private

  def get_key_object(key)
    private_key = key.to_der.unpack("H*")[0]
    fingerprint = key.fingerprint
    variable_to_return = {}
    variable_to_return[:privateKey] = private_key
    variable_to_return[:fingerprint] = fingerprint
    variable_to_return
  end

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

  def numeric? val
    val == val.to_i.to_s
  end

end
