module AnnotationsHandler
  def create_annotations(resource,policy_id, annotations)
    records = annotations.map { |annotation| [resource.id, annotation['name'], annotation['value'].to_s, policy_id] }
    resource.annotations_dataset.import(%i[resource_id name value policy_id], records)
  end

  def annotation_value_by_name(secret, name)
    annotations = secret.annotations
    target_annotation = annotations.find { |annotation| annotation.name == name }
    if target_annotation
      target_annotation.value
    else
      nil
    end
  end
end