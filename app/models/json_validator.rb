# frozen_string_literal: true

# Allows for validation of parameter presence in json objects
class JsonValidator < ActiveModel::EachValidator
  attr_reader :record

  def validate_each(record, _, _)
    @record = record

    @record.errors.add(:json_data, missing_params_message) unless missing_params.empty?
    @record.errors.add(:json_data, extra_params_message) unless extra_params.keys.empty?
  end

  private

  def json_parameter_names
    @json_parameter_names = record.json_parameter_names
  end

  def extra_params
    @extra_params = record.parameters.select { |key, _| !json_parameter_names.include?(key) }
  end
  
  def missing_params
    @missing_params = record.json_parameter_names.select { |key| !record.parameters.key?(key) }
  end

  def missing_params_message
    "missing parameters: #{missing_params.join(',')}"
  end

  def extra_params_message
    "extraneous parameters: #{extra_params.keys.join(',')}"
  end
end
