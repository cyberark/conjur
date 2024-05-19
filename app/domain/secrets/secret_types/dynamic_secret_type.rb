module Secrets
  module SecretTypes
    class DynamicSecretType  < SecretBaseType
      DYNAMIC_ISSUER = "dynamic/issuer"
      DYNAMIC_TTL = "dynamic/ttl"
      DYNAMIC_METHOD = "dynamic/method"

      def create_input_validation(params)
        super(params)

        # check if value field exist
        raise ApplicationController::UnprocessableEntity, "Adding value to a dynamic secret is not allowed" if params[:value]
        # check the secret under the correct branch
        branch = params[:branch]
        if branch.start_with?("/")
          branch = branch[1..-1]
        end
        raise ApplicationController::UnprocessableEntity, "Dynamic secrets must be created under #{Issuer::DYNAMIC_VARIABLE_PREFIX}" unless is_dynamic_branch(branch)

        dynamic_input_validation("#{branch}/#{params[:name]}", params)
      end

      def update_input_validation(params, body_params)
        secret = super(params, body_params)

        branch = params[:branch]
        if branch.start_with?("/")
          branch = branch[1..-1]
        end
        dynamic_input_validation("#{branch}/#{params[:name]}", body_params)

        secret
      end

      def get_create_permissions(params)
        permissions = super(params)

        #For Dynamic Secret - has 'use' permissions to issuer policy
        issuer = params[:issuer]
        issuer_policy = get_resource("policy", "conjur/issuers/#{issuer}")
        issuer_permissions = {issuer_policy => :use}

        permissions.merge! issuer_permissions
      end

      def get_update_permissions(params, secret)
        permissions = super(params, secret)

        #For Ephemeral Secret - has 'use' permissions to issuer policy
        issuer = params[:issuer]
        issuer_policy = get_resource("policy", "conjur/issuers/#{issuer}")
        issuer_permissions = {issuer_policy => :use}

        permissions.merge! issuer_permissions
      end

      def collect_all_permissions(params)
        allowed_privilege = %w[read execute]
        collect_all_valid_permissions(params, allowed_privilege)
      end

      def create_secret(branch, secret_name, params)
        secret = super(branch, secret_name, params)

        as_json(branch, secret_name, secret)
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", secret_id)
      end

      def replace_secret(branch, secret_name, secret, params)
        super(branch, secret, params)

        as_json(branch, secret_name, secret)
      end

      def as_json(branch, name, variable)
        # Create json result from branch and name
        json_result = super(branch, name)

        # add the dynamic fields to the result
        annotations = get_annotations(variable)
        json_result = annotation_to_json_field(annotations, DYNAMIC_ISSUER, "issuer", json_result)
        json_result = annotation_to_json_field(annotations, DYNAMIC_TTL, "ttl", json_result, false, true)
        json_result = annotation_to_json_field(annotations, DYNAMIC_METHOD, "method", json_result)

        # get specific dynamic type
        dynamic_secret_method = json_result[:method]
        dynamic_secret_type = Secrets::SecretTypes::DynamicSecretTypeFactory.new.create_dynamic_secret_type(dynamic_secret_method)
        json_result = dynamic_secret_type.method_params_as_json(annotations, json_result)

        # add annotations to json result
        json_result = json_result.merge(annotations: annotations)

        # add permissions to json result
        json_result = json_result.merge(permissions: get_permissions(variable))

        json_result.to_json
      end

      private

      def convert_fields_to_annotations(params)
        annotations = super(params)
        add_annotation(annotations, DYNAMIC_ISSUER, params[:issuer])
        add_annotation(annotations, DYNAMIC_TTL, params[:ttl])
        add_annotation(annotations, DYNAMIC_METHOD, params[:method])
        annotations
      end

      def add_annotation(annotations, annotation_name, annotation_value)
        if annotation_value
          annotation = {}
          annotation.store('name', annotation_name)
          annotation.store('value', annotation_value)
          annotations.push(annotation)
        end
      end

      def dynamic_input_validation(secret_name, params)
        # check if value field exist
        raise ApplicationController::UnprocessableEntity, "Adding value to a dynamic secret is not allowed" if params[:value]

        data_fields = {
          issuer: {
            field_info: {
              type: String,
              value: params[:issuer]
            },
            validators: [method(:validate_field_required), method(:validate_field_type), method(:validate_id)]
          },
          ttl: {
            field_info: {
              type: Integer,
              value: params[:ttl]
            },
            validators: [method(:validate_field_type), method(:validate_positive_integer)]
          }
        }
        validate_data_fields(data_fields)

        # check if issuer exists
        issuer_id = params[:issuer]
        issuer = Issuer.where(issuer_id: issuer_id).first
        raise Exceptions::RecordNotFound, "#{account}:issuer:#{issuer_id}" unless issuer

        begin
          IssuerTypeFactory.new.create_issuer_type(issuer[:issuer_type]).validate_variable(secret_name, params[:method], params[:ttl], issuer)
        rescue ArgumentError => e
          raise ApplicationController::UnprocessableEntity, e.message
        end
      end
    end
  end
end
