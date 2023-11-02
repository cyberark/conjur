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
end