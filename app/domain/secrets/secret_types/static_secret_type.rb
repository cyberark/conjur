module Secrets
  module SecretTypes
    class StaticSecretType  < SecretBaseType
      include ParamsValidator
      include AnnotationsHandler

      MIME_TYPE_ANNOTATION = "conjur/mime_type"

      def input_validation(params)
        super(params)

        data_fields = {
          mime_type: String
        }
        validate_data(params, data_fields)
      end

      def set_value(variable_resource, value)
        unless value.nil? || value.empty?
          Secret.create(resource_id: variable_resource.id, value: value)
          variable_resource.enforce_secrets_version_limit
        end
      end

      def convert_fields_to_annotations(params)
        annotations = super(params)
        # add mime type annotation
        annotations[MIME_TYPE_ANNOTATION] ||= params[:mime_type] if params[:mime_type]

        annotations
      end

      def get_mime_type(variable)
        annotation_value_by_name(variable, MIME_TYPE_ANNOTATION)
      end

      def as_json(branch, name, variable)
        super(branch, name).merge(
          mime_type: get_mime_type(variable),
        )
      end
    end
  end
end

