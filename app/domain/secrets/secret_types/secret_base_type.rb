module Secrets
  module SecretTypes
    class SecretBaseType
      include PermissionsHandler
      include AnnotationsHandler
      include ResourcesHandler

      def create_input_validation(params)
        data_fields = {
          name: {
            field_info: {
              type: String,
              value: params[:name]
            },
            validators: [method(:validate_field_required), method(:validate_field_type), method(:validate_id)]
          },
          branch: {
            field_info: {
              type: String,
            value: params[:branch]
            },
            validators: [method(:validate_field_required), method(:validate_field_type)]
          }
        }
        validate_data_fields(data_fields)

        # check policy exists
        get_resource("policy", params[:branch])
      end

      def update_input_validation(params, body_params )
        #check branch and secret name are not part of body
        raise ApplicationController::UnprocessableEntity, "'branch' is not allowed in the request body" if body_params[:branch]
        raise ApplicationController::UnprocessableEntity, "'name' is not allowed in the request body" if body_params[:name]

        # check secret exists
        get_resource("variable", "#{params[:branch]}/#{params[:name]}")
      end

      def get_input_validation(params)
        # check secret exists
        branch = params[:branch]
        secret_name = params[:name]
        get_resource("variable", "#{branch}/#{secret_name}")
      end

      def get_create_permissions(params)
        policy = get_resource("policy", params[:branch])
        { policy => :update }
      end

      def get_read_permissions(variable)
        { variable => :read }
      end

      def get_update_permissions(params, secret)
        policy = get_resource("policy", params[:branch])
        { policy => :update }
      end

      def create_secret(branch, secret_name, params)
        policy_id = full_resource_id("policy", branch)
        secret = create_resource(branch, secret_name, policy_id)

        # Add annotations
        annotations = merge_annotations(params)
        create_annotations(secret, policy_id, annotations)

        # Add permissions
        resources_privileges = collect_all_permissions(params)
        add_permissions(resources_privileges, secret.id, policy_id)

        secret
      end

      def replace_secret(branch, secret, params)
        # update annotations
        annotations = merge_annotations(params)
        # Remove all resource annotations
        delete_resource_annotations(secret)
        # Add all current annotations
        policy_id = full_resource_id("policy", branch)
        create_annotations(secret, policy_id, annotations)

        # update permissions
        resources_privileges = collect_all_permissions(params)
        # Remove all resource permissions
        delete_resource_permissions(secret)
        # Add all current permissions
        add_permissions(resources_privileges, secret.id, policy_id)
      end

      def as_json(branch, name)
        # We want always return the full path syntax in response
        unless branch.start_with?("/")
          branch = "/#{branch}"
        end
        {
          branch: branch,
          name: name
        }
      end

      def is_dynamic_branch(branch)
        # We want to make sure the branch start with full path of dynamic to prevent cases where the branch name contains dynamic
        unless branch.end_with?("/")
          branch = "#{branch}/"
        end
        branch.start_with?(Issuer::DYNAMIC_VARIABLE_PREFIX)
      end

      private

      def create_resource(branch, secret_name, policy_id)
        secret_id = full_resource_id("variable", "#{branch}/#{secret_name}")
        # Create variable resource
        ::Resource.create(resource_id: secret_id, owner_id: policy_id, policy_id: policy_id)
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", secret_id)
      end

      def merge_annotations(params)
        annotations = convert_fields_to_annotations(params)
        # add annotations from secret fields
        params_annotations = params[:annotations]
        if params_annotations
          validate_annotations(params_annotations)
          annotations.concat(params_annotations)
        end

        annotations
      end

      def convert_fields_to_annotations(params)
        []
      end

      def collect_all_permissions(params)
        permissions = []
        if params[:permissions]
          permissions = params[:permissions]
        end
        allowed_privilege = %w[read execute update]
        validate_permissions(permissions, allowed_privilege)
      end

      def annotation_to_json_field(annotations, annotation_name, field_name, json_result, required=true, convert_to_int=false)
        annotation_entity = annotations.find { |hash| hash[:name] == annotation_name }
        annotation_value = nil
        if annotation_entity
          annotation_value = annotation_entity[:value]
          if convert_to_int
            annotation_value = annotation_value.to_i
          end
          annotations.delete(annotation_entity)
        elsif required  # If the field is required but there is no annotation for it we will set it as empty
          annotation_value = ""
        end
        if annotation_value
          json_result[field_name.to_sym] = annotation_value
        end
        json_result
      end
    end
  end
end
