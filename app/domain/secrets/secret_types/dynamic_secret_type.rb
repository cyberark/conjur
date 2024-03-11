module Secrets
  module SecretTypes
    class DynamicSecretType  < SecretBaseType
      DYNAMIC_ISSUER = "dynamic/issuer"
      DYNAMIC_TTL = "dynamic/ttl"
      DYNAMIC_METHOD = "dynamic/method"

      def input_validation(params)
        super(params)

        # check if value field exist
        raise ApplicationController::BadRequestWithBody, "Adding value to a dynamic secret is not allowed" if params[:value]
        # check the secret under the correct branch
        branch = params[:branch]
        if branch.start_with?("/")
          branch = branch[1..-1]
        end
        raise ApplicationController::BadRequestWithBody, "Dynamic secret can be created only under #{Issuer::DYNAMIC_VARIABLE_PREFIX}" unless branch.start_with?(Issuer::DYNAMIC_VARIABLE_PREFIX.chop)

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

      def get_create_permissions(params)
        permissions = super(params)

        #For Dynamic Secret - has 'use' permissions to issuer policy
        issuer = params[:issuer]
        issuer_policy = get_resource("policy", "conjur/issuers/#{issuer}")
        issuer_permissions = {issuer_policy => :use}

        permissions.merge! issuer_permissions
      end

      def create_secret(branch, secret_name, params)
        secret = super(branch, secret_name, params)

        as_json(branch, secret_name)
      rescue Sequel::UniqueConstraintViolation => e
        raise Exceptions::RecordExists.new("secret", secret_id)
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
    end
  end
end
