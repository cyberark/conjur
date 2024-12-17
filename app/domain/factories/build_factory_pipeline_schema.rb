# frozen_string_literal: true

module Factories
  class BuildFactoryPipelineSchema
    def initialize(logger: Rails.logger, factory_repository: DB::Repository::PolicyFactoryRepository.new)
      @factory_repository = factory_repository
      @logger = logger

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    # Accepts a `DataObjects::FactoryPipeline` struct
    def build(pipeline_factory)
      factory_schemas = [].tap do |schemas|
        pipeline_factory.factories.each do |factory|
          unless factory['factory_obj']
            Rails.logger.warn("  WARNING: No schema found for factory: #{factory['factory']}")
            next
          end

          schemas << Marshal.load(Marshal.dump(factory['factory_obj'].schema))
        end
      end

      pipeline_factory.schema = merge_schemas(factory_schema: pipeline_factory.schema, additional_schemas: factory_schemas)

      remove_readonly_attributes(pipeline_factory)

      # TODO: need to find a way to remove fields which are mapped to another required field.

      branch_required = false
      factory_schemas.each_with_index do |schema, index|
        if schema['required'].include?('branch') && !pipeline_factory.factories[index]['args'].key?('branch')
          branch_required = true
        end
      end
      unless branch_required
        pipeline_factory.schema['properties']&.delete('branch')
        if pipeline_factory.schema.key?('required')
          pipeline_factory.schema['required'] = pipeline_factory.schema['required'] - ['branch']
        end
      end
      pipeline_factory
    end

    private

    def merge_schemas(factory_schema:, additional_schemas:)
      {}.tap do |result|
        additional_schemas.reverse.each do |schema|
          result.deep_merge!(schema)
        end
        result.deep_merge!(factory_schema)
      end
    end

    def remove_readonly_attributes(factory)
      # Check for variables first:
      if (variables = factory.schema.dig('properties', 'variables', 'properties'))
        removed_variables = [].tap do |removed|
          variables.each do |key, attributes|
            if attributes['readOnly'] == true
              variables.delete(key)
              removed << key
            end
          end
        end

        # If any removed variables are required, remove them
        factory.schema['properties']['variables']['required'] = factory.schema['properties']['variables']['required'] - removed_variables

        if variables.empty?
          factory.schema['required'] = factory.schema['required'] - ['variables']
        end

        return factory
      end

      if (variables = factory.schema['properties'])
        variables.each do |key, attributes|
          if attributes['readOnly'] == true
            variables.delete(key)
          end
        end
        factory.schema['properties'] = variables
      end
      factory
    end
  end
end
