module Secrets
  module SecretTypes
    class AWSFederationTokenDynamicSecretType  < DynamicSecretType
      DYNAMIC_REGION = "dynamic/region"
      DYNAMIC_POLICY = "dynamic/inline-policy"

      def create_input_validation(params)
        super(params)

        input_validation(params)
      end

      def update_input_validation(params, body_params)
        secret = super(params, body_params)
        input_validation(body_params)
        secret
      end

      def method_params_as_json(annotations, json_result)
        method_params = {
        }
        method_params = annotation_to_json_field(annotations, DYNAMIC_REGION, "region", method_params, false)
        method_params = annotation_to_json_field(annotations, DYNAMIC_POLICY, "inline_policy", method_params, false)
        unless method_params.empty?
          json_result = json_result.merge(method_params: method_params)
        end
        json_result
      end

      private
      def input_validation(params)
        method_params = params[:method_params]
        if method_params
          data_fields = {
            region: {
              field_info: {
                type: String,
                value: method_params[:region]
              },
              validators: [method(:validate_field_type), method(:validate_region)]
            },
            inline_policy: {
              field_info: {
                type: String,
                value: method_params[:inline_policy]
              },
              validators: [method(:validate_field_type)]
            }
          }
          validate_data_fields(data_fields)
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