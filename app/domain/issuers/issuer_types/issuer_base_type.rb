# frozen_string_literal: true

module Issuers
  module IssuerTypes
    class IssuerBaseType
      REQUIRED_PARAM_MISSING = "%s is a required parameter and must be specified"

      WRONG_PARAM_TYPE = "the '%s' parameter must be a %s"

      INVALID_INPUT_PARAM =
        "invalid parameter received in the request body. Only id, type, max_ttl " \
        "and data are allowed"

      INVALID_INPUT_PARAM_UPDATE = \
        "invalid parameter received in the request body. Only max_ttl and data " \
        "are allowed"

      ID_FIELD_ALLOWED_CHARACTERS = /\A[a-zA-Z0-9+\-_]+\z/.freeze
      ID_FIELD_MAX_ALLOWED_LENGTH = 60
      NUM_OF_EXPECTED_PARAMS = 4
      NUM_OF_EXPECTED_PARAMS_UPDATE = 2

      def validate(params)
        validate_issuer_id(params[:id])
        validate_max_ttl(params[:max_ttl])
        validate_type(params[:type])
        validate_not_nil_data(params[:data])
        validate_no_added_parameters(params)
      end

      def validate_update(params)
        validate_max_ttl(params[:max_ttl]) unless params[:max_ttl].nil?
        validate_no_added_parameters_update(params)
      end

      def validate_variable(secret_id, variable_method, variable_ttl, issuer_data)
        # This method is empty because it is not needed in the base class
        # and it will be implemented in the child classes
      end

      def mask_sensitive_data_in_response(response)
        response
      end

      def handle_minimum(issuer)
        ["fetch", issuer.as_json]
      end


      private

      def validate_issuer_id(id)
        if id.nil?
          raise ApplicationController::BadRequestWithBody,
                format(IssuerBaseType::REQUIRED_PARAM_MISSING, "id")
        end

        unless id.is_a?(String)
          raise ApplicationController::BadRequestWithBody,
                format(IssuerBaseType::WRONG_PARAM_TYPE, "id", "string")
        end

        if id.empty?
          raise ApplicationController::BadRequestWithBody,
                format(IssuerBaseType::REQUIRED_PARAM_MISSING, "id")
        end

        unless id.match?(IssuerBaseType::ID_FIELD_ALLOWED_CHARACTERS)
          raise ApplicationController::BadRequestWithBody,
                "invalid 'id' parameter. Only the following characters are " \
                "supported: A-Z, a-z, 0-9, +, -, and _"
        end

        if id.length > IssuerBaseType::ID_FIELD_MAX_ALLOWED_LENGTH
          raise ApplicationController::BadRequestWithBody,
                "'id' parameter length exceeded. Limit the length to " \
                "#{IssuerBaseType::ID_FIELD_MAX_ALLOWED_LENGTH} characters"
        end
      end

      def validate_max_ttl(max_ttl)
        if max_ttl.nil?
          raise ApplicationController::BadRequestWithBody,
                format(IssuerBaseType::REQUIRED_PARAM_MISSING, "max_ttl")
        end

        unless max_ttl.is_a?(Integer) && max_ttl.positive?
          raise ApplicationController::BadRequestWithBody,
                format(
                  IssuerBaseType::WRONG_PARAM_TYPE,
                  "max_ttl",
                  "positive integer"
                )
        end

        unless max_ttl.between?(900, 43_200)
          raise ApplicationController::BadRequestWithBody,
                format(
                  IssuerBaseType::WRONG_PARAM_TYPE,
                  "max_ttl",
                  "between 900 and 43200"
                )
        end
      end

      def validate_type(type)
        if type.nil?
          raise ApplicationController::BadRequestWithBody,
                format(IssuerBaseType::REQUIRED_PARAM_MISSING, "type")
        end

        unless type.is_a?(String)
          raise ApplicationController::BadRequestWithBody,
                format(IssuerBaseType::WRONG_PARAM_TYPE, "type", "string")
        end

        if type.empty?
          raise ApplicationController::BadRequestWithBody,
                format(IssuerBaseType::REQUIRED_PARAM_MISSING, "type")
        end
      end

      def validate_not_nil_data(data)
        return unless data.nil?

        raise ApplicationController::BadRequestWithBody,
              format(IssuerBaseType::REQUIRED_PARAM_MISSING, "data")
      end

      def validate_no_added_parameters_update(params)
        return unless params.keys.count > IssuerBaseType::NUM_OF_EXPECTED_PARAMS_UPDATE

        raise ApplicationController::BadRequestWithBody,
              IssuerBaseType::INVALID_INPUT_PARAM_UPDATE
      end

      def validate_no_added_parameters(params)
        return unless params.keys.count != IssuerBaseType::NUM_OF_EXPECTED_PARAMS

        raise ApplicationController::BadRequestWithBody,
              IssuerBaseType::INVALID_INPUT_PARAM
      end
    end
  end
end
