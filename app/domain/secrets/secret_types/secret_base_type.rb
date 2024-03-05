module Secrets
  module SecretTypes
    class SecretBaseType
      include PermissionsHandler
      include AnnotationsHandler
      include ResourcesHandler

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

      def create_secret(branch, secret_name, params)
        policy_id = full_resource_id("policy", branch)
        secret = create_resource(branch, secret_name, policy_id)

        # Add annotations
        annotations = merge_annotations(params)
        create_annotations(secret, policy_id, annotations)

        # Add permissions
        if params[:permissions]
          allowed_privilege = %w[read execute update]
          add_permissions(secret.id, policy_id, params[:permissions], allowed_privilege)
        end

        secret
      end

      def as_json(branch, name)
        {
          name: name,
          branch: branch
        }
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
        if params[:annotations]
          annotations.concat(params[:annotations])
        end

        annotations
      end

      def convert_fields_to_annotations(params)
        []
      end
    end
  end
end
