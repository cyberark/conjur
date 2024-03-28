module Secrets
  module SecretTypes
    class AWSAssumeRoleDynamicSecretType < DynamicSecretType
      DYNAMIC_ROLE_ARN = "dynamic/role-arn"
      DYNAMIC_REGION = "dynamic/region"
      DYNAMIC_POLICY = "dynamic/inline-policy"

      def method_params_as_json(annotations, json_result)
        method_params = {
        }
        method_params = annotation_to_json_field(annotations, DYNAMIC_ROLE_ARN, "role_arn", method_params)
        method_params = annotation_to_json_field(annotations, DYNAMIC_REGION, "region", method_params, false)
        method_params = annotation_to_json_field(annotations, DYNAMIC_POLICY, "inline_policy", method_params, false)
        json_result.merge(method_params: method_params)
      end

      def create_input_validation(params)
        super(params)

        input_validation(params)
      end

      def update_input_validation(params, body_params)
        secret = super(params, body_params)
        input_validation(body_params)
        secret
      end

      private

      def convert_fields_to_annotations(params)
        annotations = super(params)
        method_params = params[:method_params]
        add_annotation(annotations, DYNAMIC_ROLE_ARN, method_params[:role_arn])
        add_annotation(annotations, DYNAMIC_REGION, method_params[:region])
        add_annotation(annotations, DYNAMIC_POLICY, method_params[:inline_policy])
        annotations
      end

      def input_validation(params)
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
    end
  end
end