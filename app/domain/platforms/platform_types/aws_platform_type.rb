require_relative './platform_base_type'

class AwsPlatformType < PlatformBaseType
  REQUIRED_DATA_PARAM_MISSING = "%s is a required parameter in data and must be specified".freeze
  
  def validate(params)
    super
    validate_data(params[:data])
  end

  def default_secret_method
    "iam_session"
  end
end

private

def validate_data(data)
  unless data.is_a?(ActionController::Parameters)
    raise ApplicationController::BadRequest, "data must be a valid JSON object"
  end

  data_fields = {
    access_key_id: "access_key_id",
    access_key_secret: "access_key_secret"
  }

  data_fields.each do |field_symbol, field_string|
    if data[field_symbol].nil?
      raise ApplicationController::BadRequest, format(PlatformBaseType::REQUIRED_PARAM_MISSING, field_string)
    end
    
    unless data[field_symbol].is_a?(String)
      raise ApplicationController::BadRequest, format(PlatformBaseType::WRONG_PARAM_TYPE, field_string, "string")
    end

    if data[field_symbol].empty?
      raise ApplicationController::BadRequest, format(PlatformBaseType::REQUIRED_PARAM_MISSING, field_string)
    end
  end
end