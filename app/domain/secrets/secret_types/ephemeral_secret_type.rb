module Secrets
  module SecretTypes
    class EphemeralSecretType  < SecretBaseType
      EPHEMERAL_ISSUER = "ephemeral/issuer"
      EPHEMERAL_TTL = "ephemeral/ttl"

      def initialize_ephemeral_type(type, type_params)
        @secret_type = EphemeralSecretTypeFactory.new.create_ephemeral_secret_type(type, type_params)
      end

      def input_validation(params)
        super(params)

        # check ephemeral sub object exists
        raise Errors::Conjur::ParameterMissing, "ephemeral" unless params[:ephemeral]
        # check if value field exist
        raise ApplicationController::BadRequestWithBody, "Adding value to an ephemeral secret is not allowed" if params[:value]
        # check the secret under the correct branch
        branch = params[:branch]
        if branch.start_with?("/")
          branch = branch[1..-1]
        end
        raise ApplicationController::BadRequestWithBody, "Ephemeral secret can be created only under #{Issuer::EPHEMERAL_VARIABLE_PREFIX}" unless branch.start_with?(Issuer::EPHEMERAL_VARIABLE_PREFIX.chop)

        ephemeral = params[:ephemeral]

        # check all fields are filled and with correct type
        data_fields = {
          issuer: String,
          ttl: Numeric,
          type: String
        }
        validate_required_data(ephemeral, data_fields.keys)
        validate_data(ephemeral, data_fields)
        validate_ephemeral_type(ephemeral[:type])

        # check if issuer exists
        issuer_id = ephemeral[:issuer]
        issuer = Issuer.where(issuer_id: issuer_id).first
        raise Exceptions::RecordNotFound, "#{account}:issuer:#{issuer_id}" unless issuer

        # check secret ttl is less then the issuer ttl
        raise ApplicationController::BadRequestWithBody, "Ephemeral secret ttl can't be bigger then the issuer ttl #{issuer[:max_ttl]}" if ephemeral[:ttl] > issuer[:max_ttl]

        # validate input validation according to the specific ephemeral type
        initialize_ephemeral_type(ephemeral[:type], ephemeral[:type_params])
        @secret_type.input_validation(ephemeral[:type_params])
      end

      def get_create_permissions(policy, params)
        permissions = super(policy, params)

        #For Ephemeral Secret - has 'use' permissions to issuer policy
        issuer = params[:ephemeral][:issuer]
        issuer_policy_id = resource_id("policy","conjur/issuers/#{issuer}")
        issuer_policy = Resource[issuer_policy_id]
        issuer_permissions = {issuer_policy => :use}

        permissions.merge! issuer_permissions
      end

      def convert_fields_to_annotations(params)
        annotations = super(params)
        # add ephemeral annotations
        annotations[EPHEMERAL_ISSUER] = params[:ephemeral][:issuer]
        annotations[EPHEMERAL_TTL] = params[:ephemeral][:ttl]

        # add annotations of specific ephemeral type
        annotations.merge! @secret_type.convert_fields_to_annotations(params[:ephemeral][:type_params])
        annotations
      end

      private

      def validate_ephemeral_type(ephemeral_type)
        allowed_kind = %w[aws]
        unless allowed_kind.include?(ephemeral_type)
          raise Errors::Conjur::ParameterValueInvalid.new("Ephemeral type", "Allowed values are [aws]")
        end
      end
    end
  end
end