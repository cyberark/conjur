# frozen_string_literal: true

module ParamsValidator
  extend ActiveSupport::Concern

  REQUIRED_PARAM_MISSING = "%s is a required parameter and must be specified".freeze
  WRONG_PARAM_TYPE       = "the '%s' parameter must be a %s".freeze
  #ID_FIELD_MAX_ALLOWED_LENGTH = 60
  ID_FIELD_ALLOWED_CHARACTERS = /\A[a-zA-Z0-9+\-_!@#$%^*()\[\]]+\z/

  # Validates given params based on validator.
  # params may include body json which can be recursive, hence need to traverse recursively
  def validate_params(params, validator)
    params.each do |key, value|
      if value.is_a?(Hash) # value is an item in a nested json from body
        validate_params(value, validator)
      else
        unless validator.call(key, value)
          raise ApplicationController::UnprocessableEntity, "Value provided for parameter #{key} is invalid"
        end
      end
    end
  end

  def numeric_validator
    @numeric_validator ||= ->(k, v){ v.is_a?(Numeric)}
  end

  def string_length_validator(min_length=0, max_length=20)
    @string_length_validator ||= ->(k, v){(v.is_a?(String) && v.length <= max_length && v.length >= min_length)}
  end

  def validate_data(data, data_fields, params_count)
    data_fields.each do |field_symbol, field_type|
      # The field exists in data
      if data[field_symbol].nil?
        raise Errors::Conjur::ParameterMissing.new(field_symbol.to_s)
      end

      # The field is of correct type
      unless data[field_symbol].is_a?(field_type)
        raise Errors::Conjur::ParameterTypeInvalid.new(field_symbol.to_s, field_type.to_s)
      end

      # The field value is not empty
      if data[field_symbol].empty?
        raise Errors::Conjur::ParameterMissing.new(field_symbol.to_s)
      end
    end

    # We don't have more fields then expected
    if data.keys.count != params_count
      raise Errors::Conjur::NumOfParametersInvalid.new(data_fields.keys.join(", "))
    end
  end

  def validate_name(name)
    if name.nil?
      raise ApplicationController::BadRequestWithBody, format(REQUIRED_PARAM_MISSING, "name")
    end

    unless name.is_a?(String)
      raise ApplicationController::BadRequestWithBody, format(WRONG_PARAM_TYPE, "name", "string")
    end

    if name.empty?
      raise ApplicationController::BadRequestWithBody, format(REQUIRED_PARAM_MISSING, "name")
    end

    unless name.match?(ID_FIELD_ALLOWED_CHARACTERS)
      raise ApplicationController::BadRequestWithBody, "Invalid 'name' parameter. The character '/' is not allowed."
    end

    #if name.length > ID_FIELD_MAX_ALLOWED_LENGTH
    #  raise ApplicationController::BadRequestWithBody, "'name' parameter length exceeded. Limit the length to #{ID_FIELD_MAX_ALLOWED_LENGTH} characters"
    #end
  end

end
