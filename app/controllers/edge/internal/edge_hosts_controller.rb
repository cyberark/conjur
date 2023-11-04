require_relative '../../../domain/edge_logic/replication_handler'

class EdgeHostsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator
  include ReplicationHandler
  def all_hosts
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(
      "all_hosts replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"))

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

    begin
      if params[:count] == 'true'
        results = { count: sumItems }
        render(json: results)
        logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
          "all_hosts:count replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"))
      else
        results = replicate_hosts(scope)
        render(json: { "hosts": results })
        logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfullyWithLimitAndOffset.new(
          "all_hosts replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'",
          limit,
          offset
        ))
      end
    rescue => e
      raise ApplicationController::InternalServerError, e.message
    end
  end

end