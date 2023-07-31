class PlatformBaseType
  REQUIRED_PARAM_MISSING = "%s is a required parameter and must be specified".freeze
  WRONG_PARAM_TYPE       = "%s param must be a %s".freeze

  ID_FIELD_ALLOWED_CHARACTERS = /\A[a-zA-Z0-9+\-_]+\z/
  ID_FIELD_MAX_ALLOWED_LENGTH = 60
  
  def validate(params)
    validate_id(params[:id])
    validate_max_ttl(params[:max_ttl])
    validate_type(params[:type])
  end

  def default_secret_method
    raise NotImplementedError, "This method is not implemented because it's a base class"
  end
end

private

def validate_id(id)
  if id.nil?
    raise ApplicationController::BadRequest, format(PlatformBaseType::REQUIRED_PARAM_MISSING, "id")
  end
  
  unless id.is_a?(String)
    raise ApplicationController::BadRequest, format(PlatformBaseType::WRONG_PARAM_TYPE, "id", "string")
  end

  if id.empty?
    raise ApplicationController::BadRequest, format(PlatformBaseType::REQUIRED_PARAM_MISSING, "id")
  end

  unless id.match?(PlatformBaseType::ID_FIELD_ALLOWED_CHARACTERS)
    raise ApplicationController::BadRequest, "id param only supports alpha numeric characters and +-_"
  end

  if id.length > PlatformBaseType::ID_FIELD_MAX_ALLOWED_LENGTH
    raise ApplicationController::BadRequest, "id param must be up to #{PlatformBaseType::ID_FIELD_MAX_ALLOWED_LENGTH} characters"
  end
end

def validate_max_ttl(max_ttl)
  if max_ttl.nil?
    raise ApplicationController::BadRequest, format(PlatformBaseType::REQUIRED_PARAM_MISSING, "max_ttl")
  end
  
  unless max_ttl.is_a?(Integer) && max_ttl.positive?
    raise ApplicationController::BadRequest, format(PlatformBaseType::WRONG_PARAM_TYPE, "max_ttl", "positive integer")
  end

end

def validate_type(type)
  if type.nil?
    raise ApplicationController::BadRequest, format(PlatformBaseType::REQUIRED_PARAM_MISSING, "type")
  end
  
  unless type.is_a?(String)
    raise ApplicationController::BadRequest, format(PlatformBaseType::WRONG_PARAM_TYPE, "type", "string")
  end

  if type.empty?
    raise ApplicationController::BadRequest, format(PlatformBaseType::REQUIRED_PARAM_MISSING, "type")
  end
end
