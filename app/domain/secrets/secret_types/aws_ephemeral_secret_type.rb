module Secrets
  module SecretTypes
    class AWSEphemeralSecretType
      include ParamsValidator

      EPHEMERAL_METHOD = "ephemeral/method"
      EPHEMERAL_REGION = "ephemeral/region"
      EPHEMERAL_POLICY = "ephemeral/inline-policy"

      def input_validation(type_params)
        data_fields = {
          region: String
        }
        validate_required_data(type_params, data_fields.keys)
        validate_data(type_params, data_fields)
      end

      def convert_fields_to_annotations(params)
        annotations = {}
        annotations[EPHEMERAL_METHOD] = params[:method]
        annotations[EPHEMERAL_REGION] = params[:region]
        unless params[:inline_policy].nil?
          annotations[EPHEMERAL_POLICY] = params[:inline_policy]
        end

        annotations
      end
    end
  end
end
