# frozen_string_literal: true

module Factories
  class BatchRetrievePolicyFactoryResources
    def initialize(
      resource_repository: ::Resource,
      logger: Rails.logger,
      factory_resource_retriever: ::Factories::RetrievePolicyFactoryResource.new
    )
      @resource_repository = resource_repository
      @factory_resource_retriever = factory_resource_retriever
      @logger = logger

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    # Load the set of potential policies created by factories, but do it
    # by looking at the variables a role has access to. This allows roles
    # to access the factory generated variables they have access to, but don't
    # have to have access to the policy itself.
    def potential_policies(current_user)
      # Find common owner policies
      policies = @resource_repository
        .visible_to(current_user)
        .search(kind: 'variable')
        .eager(owner: proc { |ds| ds.select(:role_id) })
        .all
        .map { |resource| resource.owner.role_id}
        .uniq

      # Of those policies, find the ones that have a factory annotation
      @resource_repository
        .select(:resources.*)
        .where(resource_id: policies)
        .search(kind: 'policy')
        .all
        .select { |policy| policy.annotations.any? { |annotation| annotation.name == 'factory' }}
        .slice(0, 50) # Limit to 50 policies
    end

    def call(account:, current_user:)
      factory_resources = []
      potential_policies(current_user).each do |policy|
        @factory_resource_retriever.call(
          account: account,
          policy_identifier: policy.identifier,
          current_user: current_user
        ).bind do |factory_resource|
          factory_resources << factory_resource
        end
      end
      @success.new(factory_resources.sort { |x, y| x[:id] <=> y[:id] })
    end
  end
end
