module AnnotationsHandler
  def convert_annotations_object(params)
    annotations = {}
    unless (params[:annotations]).nil?
      params[:annotations].each do |obj|
        annotations[obj["name"]] = obj["value"]
      end
    end

    annotations
  end

  def create_annotations(resource, policy_id, annotations)
    records = Hash(annotations).map { |name, value| [resource.id, name, value.to_s, policy_id]}
    resource.annotations_dataset.import(%i[resource_id name value policy_id], records)
  end

  def annotation_value_by_name(secret, name)
    annotations = secret.annotations
    target_annotation = annotations.find { |annotation| annotation.name == name }
    return target_annotation.value if target_annotation

    raise Errors::Conjur::AnnotationNotFound.new(name, secret.id) 
  end
end

