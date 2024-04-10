class EdgeConfigurationController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator

  def max_edges_allowed
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("edge/max-allowed"))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    validate_conjur_admin_group(options[:account])
    secret_value = extract_max_edge_value(options[:account])
    begin
      render(plain: secret_value, content_type: "text/plain")
      logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge/max-allowed"))
    rescue => e
      logger.error(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    end
  end

  def get_role
    log_message = "Validating role '#{current_user.id}'"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    begin
      render json: {
        is_Conjur_Cloud_Admins: is_group_ancestor_of_role(current_user.id, "#{options[:account]}:group:Conjur_Cloud_Admins"),
        is_Conjur_Cloud_Users: is_group_ancestor_of_role(current_user.id, "#{options[:account]}:group:Conjur_Cloud_Users"),
        is_edge_hosts: is_group_ancestor_of_role(current_user.id, "#{options[:account]}:group:edge/edge-hosts") }
      logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
    rescue => e
      logger.error(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    end
  end

  EDGE_NOT_FOUND = "Edge not found"
  def get_edge_info
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("GET /agents/#{params[:account]}/#{params[:identifier]}/info"))
    allowed_params = %i[account identifier]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    verify_edge_host(options)
    if params[:identifier] != Edge.hostname_to_id(current_user.role_id)
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          "Requested identifier #{params[:identifier]} is not allowed for user #{current_user.role_id}"
        )
      )
      raise ApplicationController::Forbidden
    end
    begin
      edge = Edge.where(id: params[:identifier]).first
      if edge
        render(json: {
          id: edge.id,
          name: edge.name
        })
      else
        raise Exceptions::RecordNotFound.new(params[:identifier], message: EDGE_NOT_FOUND)
      end
      logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET /agents/#{params[:account]}/#{params[:identifier]}/info"))
    rescue Exceptions::RecordNotFound => e
      @error_message = e.message
      raise Exceptions::RecordNotFound.new(params[:identifier], message: EDGE_NOT_FOUND)
    rescue => e
      logger.error(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    end
  end
end

