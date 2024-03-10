# frozen_string_literal: true

module Secrets
  module SecretTypes
    class StaticSecretType  < SecretBaseType
      include ParamsValidator
      include AnnotationsHandler

      MIME_TYPE_ANNOTATION = "conjur/mime_type"

      def update_input_validation(params, body_params )
        #check branch and secret name are not part of body
        raise ApplicationController::UnprocessableEntity, "Branch is not allowed in the request body" if body_params[:branch]
        raise ApplicationController::UnprocessableEntity, "Secret name is not allowed in the request body" if body_params[:name]

        # check secret exists
        secret = get_resource("variable", "#{params[:branch]}/#{params[:name]}")

        data_fields = {
          mime_type: String
        }
        validate_data(body_params, data_fields)

        secret
      end

      def get_input_validation(params)
        # check secret exists
        branch = params[:branch]
        secret_name = params[:name]
        get_resource("variable", "#{branch}/#{secret_name}")
      end

      def create_input_validation(params)
        super(params)

        data_fields = {
          mime_type: String
        }
        validate_data(params, data_fields)

        # Can't create the secret under dynamic branch
        branch = params[:branch]
        if branch.start_with?("/")
          branch = branch[1..-1]
        end
        raise ApplicationController::BadRequestWithBody, "Static secret cannot be created under #{Issuer::DYNAMIC_VARIABLE_PREFIX}" if branch.start_with?(Issuer::DYNAMIC_VARIABLE_PREFIX.chop)
      end

      def create_secret(branch, secret_name, params)
        secret = super(branch, secret_name, params)

        # Set secret value
        set_value(secret, params[:value])

        as_json(branch, secret_name, secret)
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", secret_id)
      end

      def replace_secret(branch, secret_name, secret, params)
        super(branch, secret, params)

        # Set secret value
        set_value(secret, params[:value])

        as_json(branch, secret_name, secret)
      end

      def as_json(branch, name, variable)
        # Create json result from branch and name
        json_result = super(branch, name)

        # add the mime type field to the result
        mime_type = get_mime_type(variable)
        if mime_type
          json_result = json_result.merge(mime_type: get_mime_type(variable))
        end

        # add annotations to json result
        filter_list = ["conjur/mime_type"]
        json_result = json_result.merge(annotations: get_annotations(variable, filter_list))

        json_result.to_json
      end

      def get_update_permissions(params, secret)
        permissions = super(params, secret)

        # Update permissions on the secret
        secret_permissions = {secret => :update}

        permissions.merge! secret_permissions
      end

      private


      def set_value(secret, value)
        unless value.nil? || value.empty?
          Secret.create(resource_id: secret.id, value: value)
          secret.enforce_secrets_version_limit
        end
      end

      def convert_fields_to_annotations(params)
        mime_type_annotation = nil
        if params[:mime_type]
          mime_type_annotation = {}
          mime_type_annotation.store('name', MIME_TYPE_ANNOTATION)
          mime_type_annotation.store('value', params[:mime_type])
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
