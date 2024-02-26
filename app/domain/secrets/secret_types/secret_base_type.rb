module Secrets
  module SecretTypes
    class SecretBaseType
      include PermissionsHandler
      include AnnotationsHandler
      include ResourcesHandler

      def create_secret(secret_id, params, response)
        policy_id = full_resource_id("policy", params[:branch])
        # Create variable resource
        variable_resource = ::Resource.create(resource_id: secret_id, owner_id: policy_id, policy_id: policy_id)

        # Add annotations
        if params[:annotations].nil?
          response["annotations"] = "[]"
        end
        annotations = add_annotations(params)
        create_annotations(variable_resource, policy_id, annotations)

        # Add permissions
        if params[:permissions].nil?
          response["permissions"] = "[]"
        else
          allowed_privilege = %w[read execute update]
          resources_privileges = validate_permissions(params[:permissions], allowed_privilege)
          add_permissions(resources_privileges, secret_id, policy_id)
        end

        # Set secret value
        set_value(variable_resource, params[:value])

        # remove value field if exists from the response
        response.delete("value")

        # Convert the modified data back to a JSON string
        JSON.generate(response)
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", secret_id)
      end

      def input_validation(params)
        data_fields = {
          name: String,
          branch: String
        }
        validate_required_data(params, data_fields.keys)
        validate_data(params, data_fields)

        # Validate the name of the secret is correct
        validate_name(params[:name])

        # check policy exists
        policy_id = full_resource_id("policy", params[:branch])
        policy = Resource[policy_id]
        raise Exceptions::RecordNotFound, policy_id unless policy
      end

      def get_create_permissions(params)
        policy = get_resource("policy", params[:branch])
        { policy => :update }
      end

      def get_read_permissions(variable)
        { variable => :read }
      end

      def set_value(variable_resource, value)
        # No implementation
      end

      def convert_fields_to_annotations(params)
        { "conjur/kind" => params[:type] }
      end

      def as_json(branch, name)
        {
          name: name,
          branch: branch
        }
      end

      private

      def add_annotations(params)
        annotations = convert_annotations_object(params)
        # create annotations from secret fields
        annotations.merge!(convert_fields_to_annotations(params))

        annotations
      end
    end
  end
end
