# frozen_string_literal: true

module ParamsValidator
  extend ActiveSupport::Concern

  ID_FIELD_MAX_ALLOWED_LENGTH = 60
  ID_FIELD_ALLOWED_CHARACTERS = /\A[a-zA-Z0-9_]+\z/

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

  def validate_required_data(data, data_fields)
    data_fields.each do | field_symbol |
      # The field exists in data
      if data[field_symbol].nil?
        raise Errors::Conjur::ParameterMissing.new(field_symbol.to_s)
      end
    end
  end

  def validate_data(data, data_fields)
    data_fields.each do |field_symbol, field_type|
      unless data[field_symbol].nil?
        # The field is of correct type
        unless data[field_symbol].is_a?(field_type)
          raise Errors::Conjur::ParameterTypeInvalid.new(field_symbol.to_s, field_type.to_s)
        end

        # The field value is not empty
        if data[field_symbol].is_a?(String) and data[field_symbol].empty?
          raise Errors::Conjur::ParameterMissing.new(field_symbol.to_s)
        end
      end
    end
  end

  def validate_name(name)
    unless name.match?(ID_FIELD_ALLOWED_CHARACTERS)
      raise ApplicationController::BadRequestWithBody, "Invalid 'name' parameter. Only the following characters are supported: A-Z, a-z, 0-9 and _"
    end

    if name.length > ID_FIELD_MAX_ALLOWED_LENGTH
      raise ApplicationController::BadRequestWithBody, "'name' parameter length exceeded. Limit the length to #{ID_FIELD_MAX_ALLOWED_LENGTH} characters"
    end
  end

end
