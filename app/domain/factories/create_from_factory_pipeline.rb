# frozen_string_literal: true

module Factories
  class CreateFromFactoryPipeline
    def initialize(
      pipeline_builder: Factories::BuildFactoryPipelineSchema.new,
      factory_repository: DB::Repository::PolicyFactoryRepository.new,
      factory_creator: Factories::CreateFromPolicyFactory.new,
      base: Factories::Base.new,
      logger: Rails.logger
    )
      @pipeline_builder = pipeline_builder
      @factory_repository = factory_repository
      @factory_creator = factory_creator
      @logger = logger

      @base = base

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def call(factory_template:, request_body:, account:, context:, request_method: 'POST', identifier: nil, additional_params: {})
      pipeline_factory = @pipeline_builder.build(factory_template)
      @base.validate_and_transform_request(
        schema: pipeline_factory.schema,
        params: request_body,
        identifier: identifier,
        additional_params: additional_params
      ).bind do |body_variables|
        responses = []
        pipeline_factory.factories.each do |child_factory|
          next unless child_factory['factory_obj'].is_a?(DB::Repository::DataObjects::PolicyFactory)

          formatted_args = {}.tap do |child_args|
            (child_factory['args'] || {}).each do |key, value|
              @base.renderer.render(template: value, variables: body_variables).bind do |path|
                child_args[key] = path
              end
            end
          end
          args = body_variables.deep_merge(formatted_args)

          response = @factory_creator.call(
            factory_template: child_factory['factory_obj'],
            request_body: args.to_json,
            request_method: request_method,
            account: account,
            context: context
          )
          responses << response
        end
        @success.new(responses)
      end
    end
  end
end
