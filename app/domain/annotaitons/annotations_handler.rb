module AnnotationsHandler
  def create_annotations(resource,policy_id, annotations)
    records = annotations.map { |annotation| [resource.id, annotation['name'], annotation['value'].to_s, policy_id] }
    resource.annotations_dataset.import(%i[resource_id name value policy_id], records)
  end

  def delete_resource_annotations(resource)
    Annotation.where(resource_id: resource.id).delete
  end

  def annotation_value_by_name(resource, name)
    annotations = resource.annotations
    target_annotation = annotations.find { |annotation| annotation.name == name }
    if target_annotation
      target_annotation.value
    else
      nil
    end
  end
end