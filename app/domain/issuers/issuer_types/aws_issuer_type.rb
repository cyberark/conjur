require_relative './issuer_base_type'

class AwsIssuerType < IssuerBaseType
  REQUIRED_DATA_PARAM_MISSING = "'%s' is a required parameter in data and must be specified".freeze
  INVALID_INPUT_PARAM         = "invalid parameter received in data. Only access_key_id and secret_access_key are allowed".freeze
  NUM_OF_EXPECTED_DATA_PARAMS = 2
  
  def validate(params)
    super
    validate_data(params[:data])
  end
end

private

def validate_data(data)
  unless data.is_a?(ActionController::Parameters)
    raise ApplicationController::BadRequest, "'data' is not a valid JSON object; ensure that 'data' is properly formatted as a JSON object."
  end

  data_fields = {
    access_key_id: "access_key_id",
    secret_access_key: "secret_access_key"
  }

  data_fields.each do |field_symbol, field_string|
    if data[field_symbol].nil?
      raise ApplicationController::BadRequest, format(IssuerBaseType::REQUIRED_PARAM_MISSING, field_string)
    end
    
    unless data[field_symbol].is_a?(String)
      raise ApplicationController::BadRequest, format(IssuerBaseType::WRONG_PARAM_TYPE, field_string, "string")
    end

    if data[field_symbol].empty?
      raise ApplicationController::BadRequest, format(IssuerBaseType::REQUIRED_PARAM_MISSING, field_string)
    end
  end

  if data.keys.count != AwsIssuerType::NUM_OF_EXPECTED_DATA_PARAMS
    raise ApplicationController::BadRequest, AwsIssuerType::INVALID_INPUT_PARAM
  end
end