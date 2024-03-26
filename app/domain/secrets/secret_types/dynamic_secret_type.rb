module Secrets
  module SecretTypes
    class DynamicSecretType  < SecretBaseType
      DYNAMIC_ISSUER = "dynamic/issuer"
      DYNAMIC_TTL = "dynamic/ttl"
      DYNAMIC_METHOD = "dynamic/method"

      def create_input_validation(params)
        super(params)

        # check if value field exist
        raise ApplicationController::BadRequestWithBody, "Adding value to a dynamic secret is not allowed" if params[:value]
        # check the secret under the correct branch
        branch = params[:branch]
        if branch.start_with?("/")
          branch = branch[1..-1]
        end
        raise ApplicationController::BadRequestWithBody, "Dynamic secret can be created only under #{Issuer::DYNAMIC_VARIABLE_PREFIX}" unless branch.start_with?(Issuer::DYNAMIC_VARIABLE_PREFIX.chop)

        dynamic_input_validation(params)
      end

      def update_input_validation(params, body_params)
        secret = super(params, body_params)

        dynamic_input_validation(body_params)

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
        annotations = get_annotations(variable, [])
        json_result = add_dynamic_annotation(annotations, DYNAMIC_ISSUER, "issuer", json_result)
        json_result = add_dynamic_annotation(annotations, DYNAMIC_TTL, "ttl", json_result, true,true)
        json_result = add_dynamic_annotation(annotations, DYNAMIC_METHOD, "method", json_result)

        # get specific dynamic type
        dynamic_secret_method = json_result[:method]
        dynamic_secret_type = Secrets::SecretTypes::DynamicSecretTypeFactory.new.create_dynamic_secret_type(dynamic_secret_method)
        json_result = dynamic_secret_type.add_method_params(annotations, json_result)

        # add annotations to json result
        annotations = annotations.map { |annotation| { name: annotation.name, value: annotation.value } }
        json_result = json_result.merge(annotations: annotations)

        # add permissions to json result
        json_result = json_result.merge(permissions: get_permissions(variable))

        json_result.to_json
      end

      private

      def add_dynamic_annotation(annotations, annotation_name, field_name, json_result, required=true, convert_to_int=false)
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

      def dynamic_input_validation(params)
        # check if value field exist
        raise ApplicationController::BadRequestWithBody, "Adding value to a dynamic secret is not allowed" if params[:value]

        # check all fields are filled and with correct type
        data_fields = {
          issuer: String,
          ttl: Numeric
        }
        validate_required_data(params, data_fields.keys)
        validate_data(params, data_fields)

        # check if issuer exists
        issuer_id = params[:issuer]
        issuer = Issuer.where(issuer_id: issuer_id).first
        raise Exceptions::RecordNotFound, "#{account}:issuer:#{issuer_id}" unless issuer

        # check secret ttl is less then the issuer ttl
        raise ApplicationController::BadRequestWithBody, "Dynamic secret ttl can't be bigger than the issuer ttl #{issuer[:max_ttl]}" if params[:ttl] > issuer[:max_ttl]
      end
    end
  end
end
