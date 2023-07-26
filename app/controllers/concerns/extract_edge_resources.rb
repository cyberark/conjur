module ExtractEdgeResources
  extend ActiveSupport::Concern

  def extract_max_edge_value(account)
    id = account + ":variable:edge/edge-configuration/max-edge-allowed"
    Secret.where(:resource_id.like(id)).last.value
  end
end
