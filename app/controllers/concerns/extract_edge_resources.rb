module ExtractEdgeResources
  extend ActiveSupport::Concern

  def extract_max_edge_value(account)
    id = account + ":variable:edge/edge-configuration/max-edge-allowed"
    secret = Resource[resource_id: id].secret
    raise Exceptions::RecordNotFound.new(id,
                message: "max-edge-allowed secret doesn't exist. This might indicate that Edge was not enabled for this tenant") unless secret
    secret.value
  end
end
