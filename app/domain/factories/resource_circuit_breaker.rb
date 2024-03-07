# frozen_string_literal: true

module Factories
  # This class is responsible for tripping or reenabling the circuit breaker for a factory generated resource.
  class ResourceCircuitBreaker
    def initialize(resource_repository: ::Resource, role_repository: ::Role, logger: Rails.logger, policy_loader: CommandHandler::Policy.new)
      @resource_repository = resource_repository
      @role_repository = role_repository
      @policy_loader = policy_loader
      @logger = logger

      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def call(account:, policy_identifier:, action:, request_ip:, role:)
      valid_action?(action.to_s.downcase).bind do |request_action|
        identify_factory_from_policy(account: account, policy_identifier: policy_identifier).bind do |factory|
          circuit_breaker_exists?(policy_identifier: policy_identifier, account: account).bind do
            group_name = factory.kind == 'authenticators' ? 'authenticatable' : 'consumers'
            # This is due to some less than obvious nuinces to policy loads with grants...
            # When a policy is loaded, any grants are actually loaded into the target
            # policy. This means we need to step up a level to target the role membership.
            target_policy = if policy_identifier.include?('/')
              policy_identifier.split('/')[0...-1].join('/')
            else
              'root'
            end
            factory_resource = policy_identifier.split('/').last
            @policy_loader.call(
              target_policy_id: "#{account}:policy:#{target_policy}",
              request_ip: request_ip,
              policy: generate_policy(action: request_action, group_name: group_name, target: factory_resource),
              loader: Loader::ModifyPolicy,
              request_type: 'PATCH',
              role: role
            )
          end
        end
      end
    end

    private

    def circuit_breaker_exists?(policy_identifier:, account:)
      if @role_repository["#{account}:group:#{policy_identifier}/circuit-breaker"].present?
        @success.new(policy_identifier)
      else
        @failure.new(
          "Factory generated policy '#{policy_identifier}' does not include a circuit-breaker group.",
          status: :not_implemented
        )
      end
    end

    def valid_action?(action)
      return @failure.new("Only 'enable' and 'disable' actions are supported.", status: :bad_request) unless %w[enable disable].include?(action)

      @success.new(action == 'enable' ? 'grant' : 'revoke')
    end

    def generate_policy(action:, group_name:, target:)
      <<~POLICY
        - !#{action}
          member: !group #{target}/#{group_name}
          role: !group #{target}/circuit-breaker
      POLICY
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
