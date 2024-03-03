module Secrets
  module SecretTypes
    class AWSAssumeRoleDynamicSecretType < DynamicSecretType
      EPHEMERAL_ROLE_ARN = "ephemeral/role-arn"
      EPHEMERAL_REGION = "ephemeral/region"
      EPHEMERAL_POLICY = "ephemeral/inline-policy"

      def input_validation(params)
        super(params)

        method_params = params[:method_params]
        if method_params.nil?
          raise Errors::Conjur::ParameterMissing.new("method_params")
        end
        data_fields = {
          role_arn: String
        }
        validate_required_data(method_params, data_fields.keys)
        data_fields = {
          role_arn: String,
          region: String,
          inline_policy: String
        }
        validate_data(method_params, data_fields)
      end

      def convert_fields_to_annotations(params)
        annotations = super(params)
        method_params = params[:method_params]
        add_annotation(annotations, EPHEMERAL_ROLE_ARN, method_params[:role_arn])
        add_annotation(annotations, EPHEMERAL_REGION, method_params[:region])
        add_annotation(annotations, EPHEMERAL_POLICY, method_params[:inline_policy])
        annotations
      end
    end
  end
end