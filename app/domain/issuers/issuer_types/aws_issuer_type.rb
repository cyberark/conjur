# frozen_string_literal: true

require_relative './issuer_base_type'

class AwsIssuerType < IssuerBaseType
  FEDERATION_TOKEN_METHOD = "federation-token"
  ASSUME_ROLE_METHOD = "assume-role"

  REQUIRED_DATA_PARAM_MISSING = "'%s' is a required parameter in data and must be specified"
  INVALID_INPUT_PARAM         = "invalid parameter received in data. Only access_key_id and secret_access_key are allowed"
  NUM_OF_EXPECTED_DATA_PARAMS = 2
  # the / slash here is not a regex delimiter, it is a literal character
  SECRET_ACCESS_KEY_FIELD_VALID_FORMAT = /[A-Za-z0-9\/\+]{40}/.freeze
  ACCESS_KEY_ID_FIELD_VALID_FORMAT = /(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}/.freeze
  INVALID_ACCESS_KEY_ID_FORMAT = "invalid 'access_key_id' parameter format. The access key ID must be a valid AWS access key ID. The valid foramt is: #{ACCESS_KEY_ID_FIELD_VALID_FORMAT}" 
  INVALID_SECRET_ACCESS_KEY_FORMAT = "invalid 'secret_access_key' parameter format. The secret access key must be a valid AWS secret access key. The valid format is: #{SECRET_ACCESS_KEY_FIELD_VALID_FORMAT}"
  def validate(params)
    super
    validate_data(params[:data])
  end

  def validate_update(params)
    super
    validate_data(params[:data])
  end

  def validate_variable(variable_method, variable_ttl, issuer_data)
    super

    validate_variable_method(variable_method)
    validate_ttl(variable_ttl, variable_method, issuer_data)
  end

  private

  def validate_variable_method(variable_method)
    unless [AwsIssuerType::FEDERATION_TOKEN_METHOD, AwsIssuerType::ASSUME_ROLE_METHOD].include?(variable_method)
      raise ArgumentError, "The method annotation in the variable definition for dynamic secret is not valid. Allowed values: assume-role, federation-token"
    end
  end
end

private

def validate_ttl(ttl, method, issuer_data)
  # ttl is not mandatory
  if ttl.nil?
    return
  end

  if method == AwsIssuerType::FEDERATION_TOKEN_METHOD
    if ttl < 900 || ttl > 43200
      message = "Dynamic variable TTL is out of range for federation token (range is 900 to 43200)"
      raise ArgumentError, message
    end
  elsif method == AwsIssuerType::ASSUME_ROLE_METHOD
    if ttl < 900 || ttl > 129600
      message = "Dynamic variable TTL is out of range for assume role (range is 900 to 129600)"
      raise ArgumentError, message
    end
  end

  validate_ttl_per_issuer(ttl, issuer_data)
end

def validate_ttl_per_issuer(ttl, issuer_data)
  return unless ttl > issuer_data[:max_ttl]

  message = "The TTL of the dynamic secret can't exceed the maximum TTL defined in the issuer."
  raise ArgumentError, message
end

def validate_data(data)
  unless data.is_a?(ActionController::Parameters)
    raise ApplicationController::BadRequestWithBody, "'data' is not a valid JSON object; ensure that 'data' is properly formatted as a JSON object."
  end

  data_fields = {
    access_key_id: "access_key_id",
    secret_access_key: "secret_access_key"
  }

  data_fields.each do |field_symbol, field_string|
    if data[field_symbol].nil?
      raise ApplicationController::BadRequestWithBody, format(IssuerBaseType::REQUIRED_PARAM_MISSING, field_string)
    end
    
    unless data[field_symbol].is_a?(String)
      raise ApplicationController::BadRequestWithBody, format(IssuerBaseType::WRONG_PARAM_TYPE, field_string, "string")
    end

    if data[field_symbol].empty?
      raise ApplicationController::BadRequestWithBody, format(IssuerBaseType::REQUIRED_PARAM_MISSING, field_string)
    end
  end

  if data.keys.count != AwsIssuerType::NUM_OF_EXPECTED_DATA_PARAMS
    raise ApplicationController::BadRequestWithBody, AwsIssuerType::INVALID_INPUT_PARAM
  end

  validate_aws_acces_key_id(data[:access_key_id])
  validate_aws_secret_access_key(data[:secret_access_key])
end

def validate_aws_acces_key_id(access_key_string)
  return if access_key_string.match?(AwsIssuerType::ACCESS_KEY_ID_FIELD_VALID_FORMAT)

  raise ApplicationController::BadRequestWithBody, AwsIssuerType::INVALID_ACCESS_KEY_ID_FORMAT
end

def validate_aws_secret_access_key(secret_access_key_string)
  return if secret_access_key_string.match?(AwsIssuerType::SECRET_ACCESS_KEY_FIELD_VALID_FORMAT)

  raise ApplicationController::BadRequestWithBody, AwsIssuerType::INVALID_SECRET_ACCESS_KEY_FORMAT
end
