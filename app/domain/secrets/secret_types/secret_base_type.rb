module Secrets
  module SecretTypes
    class SecretBaseType
      include PermissionsHandler
      include AnnotationsHandler

      def create_secret(policy, resource_id, params, response)
        # Create variable resource
        variable_resource = ::Resource.create(resource_id: resource_id, owner_id: policy[:resource_id], policy_id: policy[:resource_id])

        # Add annotations
        if params[:annotations].nil?
          response["annotations"] = "[]"
        end
        annotations = add_annotations(params)
        create_annotations(variable_resource, policy, annotations)

        # Add permissions
        if params[:permissions].nil?
          response["permissions"] = "[]"
        else
          validate_permissions(params[:permissions])
        end

        # Set secret value
        set_value(variable_resource, params[:value])
        # remove value field if exists
        response.delete("value")

        # Convert the modified data back to a JSON string
        JSON.generate(response)
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", resource_id)
      end

      def set_value(variable_resource, value)
        #No implementation
      end

      def add_annotations(params)
        # create annotations from secret fields
        annotations = convert_fields_to_annotations(params)
        # add secret annotations
        unless (params[:annotations]).nil?
          params[:annotations].each do |obj|
            annotations[obj["name"]] = obj["value"]
          end
        end

        annotations
      end

      def convert_fields_to_annotations(params)
        {"conjur/kind" => params[:type]}
      end
    end
  end
end
