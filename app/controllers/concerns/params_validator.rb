# frozen_string_literal: true

module ParamsValidator
  extend ActiveSupport::Concern

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

  def string_length_validator
    @string_length_validator ||= ->(k, v){(v.is_a?(String) && v.length <= 20)}
  end

end
