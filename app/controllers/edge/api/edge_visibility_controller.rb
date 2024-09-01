class EdgeVisibilityController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator

  def all_edges
    logger.debug{LogMessages::Endpoints::EndpointRequested.new("edge")}
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    validate_conjur_admin_group(options[:account])
    begin
      render(json: Edge.order(:name).all.map{|edge|
        {name: edge.name, ip: edge.ip, last_sync: edge.last_sync.to_i,
         version:edge.version, installation_date: edge.installation_date.to_i, platform: edge.platform}})
      logger.debug{LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge")}
    rescue => e
      logger.error(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    end
  end

  def get_edge_name
    logger.debug{LogMessages::Endpoints::EndpointRequested.new("GET edge/name/#{params[:account]}/#{params[:identifier]}")}
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
      if edge.nil?
        render(json: {error: "Edge with id #{params[:identifier]} not found"}, status: 404)
      else
        render(json: {name: edge.name})
      end
      logger.debug{LogMessages::Endpoints::EndpointFinishedSuccessfully.new("GET edge/name/#{params[:account]}/#{params[:identifier]}")}
    rescue => e
      logger.error(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    end
  end
end