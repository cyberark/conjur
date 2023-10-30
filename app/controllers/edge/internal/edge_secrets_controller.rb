require_relative '../../../domain/edge_logic/replication_handler'

class EdgeSecretsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator
  include ReplicationHandler

  # Return all secrets within offset-limit frame. Default is 0-1000
  def all_secrets
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("all_secrets"))

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
      accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
      if accepts_base64
        response.set_header("Content-Encoding", "base64")
      end

      results, failed = replicate_secrets(limit, offset, options, accepts_base64)

      logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfullyWithLimitAndOffset.new(
        "all_secrets",
        limit,
        offset
      ))
      if (failed.size > 0)
        logger.debug(LogMessages::Util::FailedSerializationOfResources.new(
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

end