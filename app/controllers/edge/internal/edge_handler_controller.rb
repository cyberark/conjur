# frozen_string_literal: true

class EdgeHandlerController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator
  def report_edge_data
    log_message = "edge telemetry for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(log_message))

    allowed_params = %i[account data_type]
    url_params = params.permit(*allowed_params)
    verify_edge_host(url_params)
    data_handlers = {'install' => EdgeLogic::DataHandlers::InstallHandler , 'ongoing' => EdgeLogic::DataHandlers::OngoingHandler}
    handler = data_handlers[url_params[:data_type]]
    raise BadRequest unless handler

    handler.new(logger).call(params, current_user.role_id, request.ip)

    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(log_message))
  end

end
