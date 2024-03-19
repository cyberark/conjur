module AnnotationsHandler
  def create_annotations(resource,policy_id, annotations)
    records = annotations.map { |annotation| [resource.id, annotation['name'], annotation['value'].to_s, policy_id] }
    resource.annotations_dataset.import(%i[resource_id name value policy_id], records)
  end

  def delete_resource_annotations(resource)
    Annotation.where(resource_id: resource.id).delete
  end

  def get_annotations(resource, filtered_out_annotations)
    # Get the annotations from the resource and filter out the annotations that are not needed
    # Return the filtered annotations as an array of hashes read for JSON
    annotations = resource.annotations
    filtered_annotations = annotations.reject { |annotation| filtered_out_annotations.include?(annotation.name) }
    filtered_annotations = filtered_annotations.map { |annotation| { name: annotation.name, value: annotation.value } }
    # Return empty list if no annotations after filter
    unless filtered_annotations
      filtered_annotations = []
    end
    filtered_annotations
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
