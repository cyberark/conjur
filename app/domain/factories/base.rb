# frozen_string_literal: true

require 'rest_client'
require 'json_schemer'

module Factories
  class Base

    attr_reader :renderer, :http, :schema_validator, :utilities, :logger, :secrets_repository, :policy_loader

    def initialize(
      renderer: Factories::Renderer.new,
      schema_validator: JSONSchemer,
      utilities: Factories::Utilities,
      secrets_repository: DB::Repository::SecretsRepository.new,
      policy_loader: CommandHandler::Policy.new
    )
      @renderer = renderer
      @schema_validator = schema_validator
      @utilities = utilities
      @secrets_repository = secrets_repository
      @policy_loader = policy_loader
      @logger = Rails.logger

      # JSON is defined here for visibility. It is not currently mocked in
      # testing, thus, we're not setting them in the initializer.
      @json = JSON

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def parse_request(params)
      return @failure.new('Request body must be JSON', status: :bad_request) if params.blank?

      @success.new(@json.parse(params))
    rescue
      @failure.new('Request body must be valid JSON', status: :bad_request)
    end

    def transform_request(params:, identifier:)
      # The param `value` is special as it handles setting a single, unnamed variable
      # within a policy (ex. for the policy factory). This shifts it to the correct
      # part of the hash so it can be processed downstream.
      if params.key?('value')
        params['variables'] = { 'value' => params.delete('value') }
      end

      # If we're updating the resource, set `id` to the identifier
      if identifier.present?
        params['id'] = identifier
      end

      # Strip keys without values
      @success.new(params.select { |_, value| value.present? })
    end

    def validate_request(schema:, params:)
      validator = @schema_validator.schema(schema, insert_property_defaults: true)
      return @success.new(params) if validator.valid?(params)

      errors = validator.validate(params).map do |error|
        case error['type']
        # When the provided value is not in the list of allowed values
        when 'enum'
          variable_name = error['schema_pointer'].split('/').reject(&:empty?)
          available_values = error['root_schema'].dig(*variable_name)['enum']
          variable_reference = if variable_name[2] == 'properties'
            variable_name.delete_at(0)
            variable_name.delete_at(1)
            variable_name.join('/')
          else
            variable_name[1..-1].join('/')
          end
          {
            message: "Value must be one of: '#{available_values.join("', '")}'",
            key: variable_reference
          }
        # When a required value is missing
        when 'required'
          missing_attributes = error['details']['missing_keys'].map{|key| [ error['data_pointer'], key].reject(&:empty?).join('/') }
          missing_attributes.map do |attribute|
            {
              message: "A value is required for '#{attribute}'",
              key: attribute
            }
          end
        else
          {
            message: "Validation error: '#{error['data_pointer']}' must be a #{error['type']}"
          }
        end
      end
      @failure.new(errors.flatten, status: :bad_request)
    end

    def validate_and_transform_request(schema:, params:, identifier: nil)
      parse_request(params).bind do |parsed_params|
        transform_request(params: parsed_params, identifier: identifier).bind do |transformed_params|
          validate_request(schema: schema, params: transformed_params)
        end
      end
    end

    def set_factory_variables(schema_variables:, factory_variables:, variable_path:, context:, account:)
      # Only set secrets defined in the policy and present in factory payload
      new_variables = {}.tap do |variables|
        (schema_variables.keys & factory_variables.keys).each do |schema_variable|
          # Handle variable name 'value' differently as it refers to the single variable
          # that takes the policy name.
          variable_id = if schema_variable == 'value'
            variable_path.to_s
          else
            "#{variable_path}/#{schema_variable}"
          end
          variables[variable_id] = factory_variables[schema_variable]
        end
      end
      @secrets_repository.update(
        account: account,
        context: context,
        variables: new_variables
      ).bind do
        return @success.new('Variables successfully set')
      end
    rescue => e
      @failure.new(
        { message: "Failed to set variables",
          exception: e }, status: :bad_request
      )
    end
  end
end
