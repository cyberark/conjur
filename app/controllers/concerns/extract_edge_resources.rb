module ExtractEdgeResources
  extend ActiveSupport::Concern

  def extract_max_edge_value(account)
    id = account + ":variable:edge/edge-configuration/max-edge-allowed"
    secret = Resource[resource_id: id]&.secret
    raise Errors::Edge::MaxEdgeAllowedNotFound.new(id: id) unless secret
    secret.value
  end
end
