class EdgeConfigurationController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator

  def max_edges_allowed
    logger.info(LogMessages::Endpoints::EndpointRequested.new("edge/max-allowed"))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    validate_conjur_admin_group(options[:account])
    begin
      secret_value = extract_max_edge_value(options[:account])
      render(plain: secret_value, content_type: "text/plain")
    rescue Exceptions::RecordNotFound
      raise RecordNotFound, "The request failed because max-edge-allowed secret doesn't exist"
    end
    logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge/max-allowed"))
  end
end