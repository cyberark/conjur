module AnnotationsHandler
  def self.create_annotations(resource,policy, annotations)
    records = Hash(annotations).map { |name, value| [resource.id, name, value.to_s, policy.id]}
    resource.annotations_dataset.import(%i[resource_id name value policy_id], records)
  end


end