module Secrets
  module SecretTypes
    class AWSFederationTokenDynamicSecretType  < DynamicSecretType
      DYNAMIC_REGION = "dynamic/region"
      DYNAMIC_POLICY = "dynamic/inline-policy"

      def input_validation(params)
        super(params)

        method_params = params[:method_params]
        if method_params
          data_fields = {
            region: String,
            inline_policy: String
          }
          validate_data(method_params, data_fields)
        end
      end

      def convert_fields_to_annotations(params)
        annotations = super(params)
        method_params = params[:method_params]
        if method_params
          add_annotation(annotations, DYNAMIC_REGION, method_params[:region])
          add_annotation(annotations, DYNAMIC_POLICY, method_params[:inline_policy])
        end
        annotations
      end
    end
  end
end