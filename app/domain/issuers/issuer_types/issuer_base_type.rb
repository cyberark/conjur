class IssuerBaseType
  REQUIRED_PARAM_MISSING = "%s is a required parameter and must be specified".freeze
  WRONG_PARAM_TYPE       = "the '%s' parameter must be a %s".freeze
  INVALID_INPUT_PARAM    = "invalid parameter received in the request body. Only id, type, max_ttl and data are allowed".freeze

  ID_FIELD_ALLOWED_CHARACTERS = /\A[a-zA-Z0-9+\-_]+\z/
  ID_FIELD_MAX_ALLOWED_LENGTH = 60
  NUM_OF_EXPECTED_PARAMS = 4
  
  def validate(params)
    validate_id(params[:id])
    validate_max_ttl(params[:max_ttl])
    validate_type(params[:type])
    validate_not_nil_data(params[:data])
    validate_no_added_parameters(params)
  end
end

private

def validate_id(id)
  if id.nil?
    raise ApplicationController::BadRequest, format(IssuerBaseType::REQUIRED_PARAM_MISSING, "id")
  end
  
  unless id.is_a?(String)
    raise ApplicationController::BadRequest, format(IssuerBaseType::WRONG_PARAM_TYPE, "id", "string")
  end

  if id.empty?
    raise ApplicationController::BadRequest, format(IssuerBaseType::REQUIRED_PARAM_MISSING, "id")
  end

  unless id.match?(IssuerBaseType::ID_FIELD_ALLOWED_CHARACTERS)
    raise ApplicationController::BadRequest, "invalid 'id' parameter. Only the following characters are supported: A-Z, a-z, 0-9, +, -, and _"
  end

  if id.length > IssuerBaseType::ID_FIELD_MAX_ALLOWED_LENGTH
    raise ApplicationController::BadRequest, "'id' parameter length exceeded. Limit the length to #{IssuerBaseType::ID_FIELD_MAX_ALLOWED_LENGTH} characters"
  end
end

def validate_max_ttl(max_ttl)
  if max_ttl.nil?
    raise ApplicationController::BadRequest, format(IssuerBaseType::REQUIRED_PARAM_MISSING, "max_ttl")
  end
  
  unless max_ttl.is_a?(Integer) && max_ttl.positive?
    raise ApplicationController::BadRequest, format(IssuerBaseType::WRONG_PARAM_TYPE, "max_ttl", "positive integer")
  end

end

def validate_type(type)
  if type.nil?
    raise ApplicationController::BadRequest, format(IssuerBaseType::REQUIRED_PARAM_MISSING, "type")
  end
  
  unless type.is_a?(String)
    raise ApplicationController::BadRequest, format(IssuerBaseType::WRONG_PARAM_TYPE, "type", "string")
  end

  if type.empty?
    raise ApplicationController::BadRequest, format(IssuerBaseType::REQUIRED_PARAM_MISSING, "type")
  end
end

def validate_not_nil_data(data)
  if data.nil?
    raise ApplicationController::BadRequest, format(IssuerBaseType::REQUIRED_PARAM_MISSING, "data")
  end
end

def validate_no_added_parameters(params)
  if params.keys.count != IssuerBaseType::NUM_OF_EXPECTED_PARAMS
    raise ApplicationController::BadRequest, IssuerBaseType::INVALID_INPUT_PARAM
  end
end
