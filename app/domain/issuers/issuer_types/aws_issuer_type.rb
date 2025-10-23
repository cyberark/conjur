# frozen_string_literal: true

module Issuers
  module IssuerTypes
    class AwsIssuerType < IssuerBaseType
      SENSITIVE_DATA_MASK = "*****"
      FEDERATION_TOKEN_METHOD = "federation-token"
      ASSUME_ROLE_METHOD = "assume-role"

      REQUIRED_DATA_PARAM_MISSING =
        "'%s' is a required parameter in data and must be specified"

      INVALID_INPUT_PARAM =
        "invalid parameter received in data. Only access_key_id and " \
        "secret_access_key are allowed"

      NUM_OF_EXPECTED_DATA_PARAMS = 2

      # the / slash here is not a regex delimiter, it is a literal character
      SECRET_ACCESS_KEY_FIELD_VALID_FORMAT = %r{[A-Za-z0-9/+]{40}}.freeze

      ACCESS_KEY_ID_FIELD_VALID_FORMAT =
        /(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}/.freeze

      INVALID_ACCESS_KEY_ID_FORMAT =
        "invalid 'access_key_id' parameter format. The access key ID must be a " \
        "valid AWS access key ID. The valid format is: " \
        "#{ACCESS_KEY_ID_FIELD_VALID_FORMAT}"

      INVALID_SECRET_ACCESS_KEY_FORMAT =
        "invalid 'secret_access_key' parameter format. The secret access key " \
        "must be a valid AWS secret access key. The valid format is: " \
        "#{SECRET_ACCESS_KEY_FIELD_VALID_FORMAT}"

      def validate(params)
        super
        validate_data(params[:data])
      end

      def validate_update(params)
        super
        return if params[:data].nil?

        validate_data(params[:data])
      end

      def validate_variable(secret_id, variable_method, variable_ttl, issuer_data)
        super

        validate_variable_method(secret_id, variable_method)
        validate_ttl(secret_id, variable_ttl, variable_method, issuer_data)
      end

      def mask_sensitive_data_in_response(response)
        super
        if response.is_a?(Array)
          response.each do |item|
            mask_data_field(item)
          end
        else
          mask_data_field(response)
        end
        response
      end

      def handle_minimum(issuer)
        operation = "fetch minimum"
        key_to_keep = "max_ttl"
        stripped_issuer = { key_to_keep => issuer[key_to_keep.to_sym] }
        result = stripped_issuer.as_json

        [operation, result]
      end

      private

      def mask_data_field(response)
        return unless response.key?(:data)

        response[:data]["secret_access_key"] = SENSITIVE_DATA_MASK
      end

      def validate_variable_method(secret_id, variable_method)
        unless [
          AwsIssuerType::FEDERATION_TOKEN_METHOD,
          AwsIssuerType::ASSUME_ROLE_METHOD
        ].include?(variable_method)
          raise ArgumentError,
                "The 'method' annotation in the variable definition for " \
                "dynamic secret \"#{secret_id}\" is not valid. Allowed values: " \
                "assume-role, federation-token"
        end
      end

      private

      def validate_ttl(secret_id, ttl, method, issuer_data)
        # ttl is not mandatory
        if ttl.nil?
          return
        end

        if method == AwsIssuerType::FEDERATION_TOKEN_METHOD
          if ttl < 900 || ttl > 43200
            raise ArgumentError,
                  "The TTL defined for dynamic secret '#{secret_id}' " \
                  "(method=federation token) is out of the allowed range: " \
                  "900-43,200 seconds."
          end
        elsif method == AwsIssuerType::ASSUME_ROLE_METHOD
          if ttl < 900 || ttl > 129600
            raise ArgumentError,
                  "The TTL defined for dynamic secret '#{secret_id}' " \
                  "(method=assumed role) is out of the allowed range: " \
                  "900-129,600 seconds."
          end
        end

        validate_ttl_per_issuer(ttl, issuer_data)
      end

      def validate_ttl_per_issuer(ttl, issuer_data)
        return unless ttl > issuer_data[:max_ttl]

        raise ArgumentError,
              "The TTL of the dynamic secret must be less than or equal to the " \
              "maximum TTL defined in the issuer. (Max TTL: #{issuer_data[:max_ttl]})"
      end

      def validate_data(data)
        unless data.is_a?(ActionController::Parameters)
          raise ApplicationController::BadRequestWithBody,
                "'data' is not a valid JSON object; ensure that 'data' is properly " \
                "formatted as a JSON object."
        end

        data_fields = {
          access_key_id: "access_key_id",
          secret_access_key: "secret_access_key"
        }

        data_fields.each do |field_symbol, field_string|
          unless data.key?(field_symbol)
            raise ApplicationController::UnprocessableEntity,
                  format(IssuerBaseType::REQUIRED_PARAM_MISSING, field_string)
          end
          if data[field_symbol].nil?
            raise ApplicationController::UnprocessableEntity,
                  format(IssuerBaseType::REQUIRED_PARAM_MISSING, field_string)
          end

          unless data[field_symbol].is_a?(String)
            raise ApplicationController::UnprocessableEntity,
                  format(IssuerBaseType::WRONG_PARAM_TYPE, field_string, "string")
          end

          if data[field_symbol].empty?
            raise ApplicationController::UnprocessableEntity,
                  format(IssuerBaseType::REQUIRED_PARAM_MISSING, field_string)
          end
        end

        if data.keys.count > AwsIssuerType::NUM_OF_EXPECTED_DATA_PARAMS
          raise ApplicationController::UnprocessableEntity,
                AwsIssuerType::INVALID_INPUT_PARAM
        end

        validate_aws_access_key_id(data[:access_key_id])
        validate_aws_secret_access_key(data[:secret_access_key])
      end

      def validate_aws_access_key_id(access_key_string)
        return if access_key_string.match?(
          AwsIssuerType::ACCESS_KEY_ID_FIELD_VALID_FORMAT
        )

        raise ApplicationController::UnprocessableEntity,
              AwsIssuerType::INVALID_ACCESS_KEY_ID_FORMAT
      end

      def validate_aws_secret_access_key(secret_access_key_string)
        return if secret_access_key_string.match?(
          AwsIssuerType::SECRET_ACCESS_KEY_FIELD_VALID_FORMAT
        )

        raise ApplicationController::UnprocessableEntity,
              AwsIssuerType::INVALID_SECRET_ACCESS_KEY_FORMAT
      end
    end
  end
end
