class EdgeSecretsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator

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
  
end