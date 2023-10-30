class EdgeVisibilityController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator

  def all_edges
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("edge"))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    validate_conjur_admin_group(options[:account])
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("edge"))
    render(json: Edge.order(:name).all.map{|edge|
      {name: edge.name, ip: edge.ip, last_sync: edge.last_sync.to_i,
       version:edge.version, installation_date: edge.installation_date.to_i, platform: edge.platform}})
  end
end