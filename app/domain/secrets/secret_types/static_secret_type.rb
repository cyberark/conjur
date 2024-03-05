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

        # Can't create the secret under ephemerals branch
        branch = params[:branch]
        if branch.start_with?("/")
          branch = branch[1..-1]
        end
        raise ApplicationController::BadRequestWithBody, "Static secret cannot be created under #{Issuer::EPHEMERAL_VARIABLE_PREFIX}" if branch.start_with?(Issuer::EPHEMERAL_VARIABLE_PREFIX.chop)
      end

      def create_secret(branch, secret_name, params)
        secret = super(branch, secret_name, params)

        # Set secret value
        set_value(secret, params[:value])

        as_json(branch, secret_name, secret)
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", secret_id)
      end

      def set_value(secret, value)
        unless value.nil? || value.empty?
          Secret.create(resource_id: secret.id, value: value)
          secret.enforce_secrets_version_limit
        end
      end

      def as_json(branch, name, variable)
        json_result = super(branch, name)

        mime_type = get_mime_type(variable)
        if mime_type
          json_result = json_result.merge(
            mime_type: get_mime_type(variable),
            )
        end

        json_result
      end

      private
      def convert_fields_to_annotations(params)
        mime_type_annotation = nil
        if params[:mime_type]
          mime_type_annotation = {}
          mime_type_annotation.store('name', 'conjur/mime_type')
          mime_type_annotation.store('value' , params[:mime_type])
        end

        annotations = []
        if mime_type_annotation
          annotations.push(mime_type_annotation)
        end
        annotations
      end

      def get_mime_type(variable)
        annotation_value_by_name(variable, MIME_TYPE_ANNOTATION)
      end
    end
  end
end

