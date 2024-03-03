module Secrets
  module SecretTypes
    class AWSFederationTokenDynamicSecretType  < DynamicSecretType
      EPHEMERAL_REGION = "ephemeral/region"
      EPHEMERAL_POLICY = "ephemeral/inline-policy"

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
          add_annotation(annotations, EPHEMERAL_REGION, method_params[:region])
          add_annotation(annotations, EPHEMERAL_POLICY, method_params[:inline_policy])
        end
        annotations
      end
    end
  end
end