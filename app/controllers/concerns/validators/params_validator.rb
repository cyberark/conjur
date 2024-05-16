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

  def validate_data_fields(fields_validations)
    fields_validations.each do |field_name, field_validation|
      field_validation[:validators].each do |validator|
        validator.call(field_name, field_validation[:field_info])
      end
    end
  end

  def numeric_validator
    @numeric_validator ||= ->(k, v){ v.is_a?(Numeric)}
  end

  def string_length_validator(min_length=0, max_length=20)
    @string_length_validator ||= ->(k, v){(v.is_a?(String) && v.length <= max_length && v.length >= min_length)}
  end

  def validate_name(name)
    unless name.match?(ID_FIELD_ALLOWED_CHARACTERS)
      raise ApplicationController::BadRequestWithBody, "Invalid 'name' parameter. Only the following characters are supported: A-Z, a-z, 0-9 and _"
    end

    if name.length > ID_FIELD_MAX_ALLOWED_LENGTH
      raise ApplicationController::BadRequestWithBody, "'name' parameter length exceeded. Limit the length to #{ID_FIELD_MAX_ALLOWED_LENGTH} characters"
    end
  end

  def validate_id(param_name, data)
    validate_string(param_name, data[:value], /\A[a-zA-Z0-9._-]+\z/, 60)
  end

  def validate_path(param_name, data)
    validate_string(param_name, data[:value], /\A[a-zA-Z0-9_\/-]+\z/, 500)
  end

  def validate_resource_id(param_name, data)
    validate_string(param_name, data[:value], /\A[a-zA-Z0-9@._\/-]+\z/, 500)
  end

  def validate_mime_type(param_name, data)
    validate_string(param_name, data[:value], /^[a-zA-Z0-9!#$&^_-]+\/[a-zA-Z0-9!\#$&^_-]+(?:\+[a-zA-Z0-9!\#$&^_-]+)?$/, 100)
  end

  def validate_role_arn(param_name, data)
    validate_string(param_name, data[:value], %r{arn:aws:iam::\d{12}:role/[\w+=,.@-]+}, 1000)
  end

  def validate_region(param_name, data)
    validate_string(param_name, data[:value], /^[a-z]+(?:-[a-z]+)?-\d+$/, 32)
  end

  def validate_annotation_value(param_name, data)
    validate_string(param_name, data[:value], /^[^<>']+$/, 120)
  end

  def validate_positive_integer(param_name, data)
    if !data[:value].nil? && data[:value] < 0
      raise ApplicationController::UnprocessableEntity, "#{param_name} must be positive number"
    end
  end

  def validate_field_required(param_name, data)
    # The field exists in data
    if data[:value].nil? || (data[:value].is_a?(String) and data[:value].empty?)
      raise Errors::Conjur::ParameterMissing.new(param_name)
    end
  end

  def validate_field_type(param_name, data)
    unless data[:value].nil?
      # The field is of correct type
      unless data[:value].is_a?(data[:type])
        raise Errors::Conjur::ParameterTypeInvalid.new(param_name, data[:type].to_s)
      end
    end
  end

  def validate_resource_kind(resource_kind, resource_id, allowed_kind)
    unless allowed_kind.include?(resource_kind)
      raise Errors::Conjur::ParameterValueInvalid.new("Resource #{resource_id} kind", "Allowed values are #{allowed_kind}")
    end
  end

  def validate_privilege(resource_id, privileges, allowed_privilege)
    privileges.each do |privilege|
      unless allowed_privilege.include?(privilege)
        raise Errors::Conjur::ParameterValueInvalid.new("Resource #{resource_id} privileges", "Allowed values are #{allowed_privilege}")
      end
    end
  end

  private
  def validate_string(param_name, data, regex_pattern, max_size)
    unless data.nil?
      unless data.match?(regex_pattern)
        raise ApplicationController::UnprocessableEntity, "Invalid '#{param_name}' parameter."
      end

      if data.length > max_size
        raise ApplicationController::UnprocessableEntity, "'#{param_name}' parameter length exceeded. Limit the length to #{max_size} characters"
      end
    end
  end

end
