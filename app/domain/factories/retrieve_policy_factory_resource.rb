# frozen_string_literal: true

module Factories
  class RetrievePolicyFactoryResource
    def initialize(
      resource_repository: ::Resource,
      logger: Rails.logger,
      policy_factory_repository: DB::Repository::PolicyFactoryRepository.new,
      secrets_repository: DB::Repository::SecretsRepository.new
    )
      @policy_factory_repository = policy_factory_repository
      @secrets_repository = secrets_repository
      @resource_repository = resource_repository
      @logger = logger

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def call(account:, policy_identifier:, current_user:)
      identify_factory_from_policy(
        account: account,
        policy_identifier: policy_identifier
      ).bind do |factory|
        load_policy_factory_variables(
          kind: factory.kind,
          version: factory.version,
          identifier: factory.factory_id,
          account: account
        ).bind do |factory_variables|
          retrieve_factory_secrets(
            account: account,
            variables: factory_variables.keys,
            policy_path: policy_identifier,
            role: current_user
          ).bind do |secrets|
            generate_response(
              variables: factory_variables,
              secrets: secrets,
              policy_identifier: policy_identifier,
              factory: factory
            )
          end
        end
      end
    end

    private

    def generate_response(variables:, secrets:, policy_identifier:, factory:)
      result = { id: policy_identifier, variables: {}, annotations: {}, details: {} }.tap do |response|
        variables.each do |variable, details|
          response[:variables][variable] = {
            value: secrets["#{policy_identifier}/#{variable}"],
            description: details['description'].to_s
          }
        end
      end
      result[:annotations] = factory.annotations
      result[:details] = {
        classification: factory.kind,
        version: factory.version,
        identifier: factory.factory_id
      }
      @success.new(result)
    end

    def retrieve_factory_secrets(account:, variables:, policy_path:, role:)
      if variables.empty?
        return @failure.new(
          "This factory created resource: '#{account}:policy:#{policy_path}' does not include any variables.",
          status: :not_found,
          exception: Errors::Factories::NoVariablesFound.new("#{account}:policy:#{policy_path}")
        )
      end
      @secrets_repository.find_all(
        account: account,
        policy_path: policy_path,
        variables: variables,
        role: role
      ).bind do |secrets|
        @success.new(secrets)
      end
    end

    def load_policy_factory_variables(kind:, version:, identifier:, account:)
      # Don't pass the role. This allows us to retrieve a factory for role that does not
      # have permission to view the factory. This should only be used to retrieve the
      # schema to retrieve factory resources.
      @policy_factory_repository.find(
        kind: kind,
        account: account,
        id: identifier,
        version: version
      ).bind do |policy_factory|
        # Do we need to account for loading a Factory without variables (ex. policy created by core Factory)?
        return @success.new(policy_factory.variables)
      end
      target_factory = "#{kind}/#{version}/#{identifier}"
      @failure.new(
        "A Policy Factory was not found for: '#{target_factory}' in account '#{account}'.",
        status: :not_found,
        exception: Errors::Factories::FactoryNotFound.new(target_factory)
      )
    end

    def identify_factory_from_policy(account:, policy_identifier:)
      policy = @resource_repository["#{account}:policy:#{policy_identifier}"]
      if policy.nil?
        return @failure.new(
          "Policy '#{policy_identifier}' was not found in account '#{account}'. Only policies with variables created from Factories can be retrieved using the Factory endpoint.",
          exception: Errors::Factories::FactoryGeneratedPolicyNotFound.new(policy_identifier),
          status: :not_found
        )
      end

      annotations = policy.annotations || []
      annotation_hash = {}.tap { |result| annotations.each {|a| result[a.name] = a.value } }
      if annotation_hash.empty? || !annotation_hash.key?('factory')
        return @failure.new(
          "Policy '#{policy_identifier}' does not have a factory annotation.",
          exception: Errors::Factories::MissingFactoryAnnotation.new(policy_identifier),
          status: :not_found
        )
      end

      factory = annotation_hash.delete('factory')

      @success.new(
        Struct.new(:kind, :version, :factory_id, :annotations).new(*factory.split('/'), annotation_hash)
      )
    end
  end
end
