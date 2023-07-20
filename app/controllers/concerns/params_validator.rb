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
        raise ApplicationController::BadRequest unless validator.call(key, value)
      end
    end
  end
end
