module AnnotationsHandler
  include ParamsValidator

  def validate_annotations(annotations)
    annotations.each do |annotation|
      data_fields = {
        "annotation name": {
          field_info: {
            type: String,
            value: annotation[:name]
          },
          validators: [method(:validate_field_required), method(:validate_field_type), method(:validate_path)]
        },
        "annotation value": {
          field_info: {
            type: String,
            value: annotation[:value]
          },
          validators: [method(:validate_field_required), method(:validate_field_type), method(:validate_annotation_value)]
        }
      }
      validate_data_fields(data_fields)
    end
  end

  def create_annotations(resource,policy_id, annotations)
    records = annotations.map { |annotation| [resource.id, annotation['name'], annotation['value'].to_s, policy_id] }
    resource.annotations_dataset.import(%i[resource_id name value policy_id], records)
  end

  def delete_resource_annotations(resource)
    Annotation.where(resource_id: resource.id).delete
  end

  def get_annotations(resource)
    annotations = resource.annotations
    annotations.map { |annotation| { name: annotation.name, value: annotation.value } }
  end
end
