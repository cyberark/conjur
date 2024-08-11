# frozen_string_literal: true
require_relative '../cache/redis_handler'

module Secrets
  module SecretTypes
    class StaticSecretType  < SecretBaseType
      include ParamsValidator
      include AnnotationsHandler
      include RedisHandler

      MIME_TYPE_ANNOTATION = "conjur/mime_type"

      def get_input_validation(params)
        secret = super(params)
        raise ApplicationController::BadRequestWithBody, "Check the branch you have provided for your static secret. The #{Issuer::DYNAMIC_VARIABLE_PREFIX} branch is reserved for dynamic secrets only." if is_dynamic_branch(params[:branch])
        secret
      end

      def update_input_validation(params, body_params )
        #check branch and secret name are not part of body
        raise ApplicationController::UnprocessableEntity, "'branch' is not allowed in the request body" if body_params[:branch]
        raise ApplicationController::UnprocessableEntity, "'name' is not allowed in the request body" if body_params[:name]
        raise ApplicationController::BadRequestWithBody, "Check the branch you have provided for your static secret. The #{Issuer::DYNAMIC_VARIABLE_PREFIX} branch is reserved for dynamic secrets only." if params[:branch] && is_dynamic_branch(params[:branch])

        # check secret exists
        secret = get_resource("variable", "#{params[:branch]}/#{params[:name]}")

        data_fields = {
          mime_type: {
            field_info: {
              type: String,
              value: body_params[:mime_type]
            },
            validators: [method(:validate_field_type), method(:validate_mime_type)]
          }
        }
        validate_data_fields(data_fields)

        secret
      end

      def create_input_validation(params)
        super(params)

        data_fields = {
          mime_type: {
            field_info: {
              type: String,
              value: params[:mime_type]
            },
            validators: [method(:validate_field_type), method(:validate_mime_type)]
          }
        }
        validate_data_fields(data_fields)

        # Can't create the secret under dynamic branch
        branch = params[:branch]
        if branch.start_with?("/")
          branch = branch[1..-1]
        end
        raise ApplicationController::UnprocessableEntity, "Choose a different branch under /data for your static secret. The #{Issuer::DYNAMIC_VARIABLE_PREFIX} branch is reserved for dynamic secrets only." if is_dynamic_branch(branch)

        if params[:issuer]
          raise ApplicationController::UnprocessableEntity, "A static secret can't contain an 'issuer' field"
        end
      end

      def collect_all_permissions(params)
        allowed_privilege = %w[read execute update]
        collect_all_valid_permissions(params, allowed_privilege)
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

        # add the static fields to the result
        annotations = get_annotations(variable)
        json_result = annotation_to_json_field(annotations, MIME_TYPE_ANNOTATION, "mime_type", json_result, false)

        # add annotations to json result
        json_result = json_result.merge(annotations: annotations)

        # add permissions to json result
        json_result = json_result.merge(permissions: get_permissions(variable))

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
          ::DB::Service::SecretService.instance.secret_value_change(secret.id, value)
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
    end
  end
end
