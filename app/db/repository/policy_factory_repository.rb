require 'base64'
require 'json'

require './app/domain/responses'

module DB
  module Repository
    module DataObjects
      PolicyFactory = Struct.new(
        :name,
        :classification,
        :version,
        :policy,
        :policy_branch,
        :schema,
        keyword_init: true
      ) do
        def description
          schema['description'].to_s
        end

        def variables
          schema.dig('properties', 'variables', 'properties') || {}
        end
      end
    end

    class PolicyFactoryRepository
      def initialize(
        policy_factories_path: Rails.application.config.conjur_config.policy_factories_path,
        data_object: DataObjects::PolicyFactory,
        resource: ::Resource,
        logger: Rails.logger
      )
        @policy_factories_path = policy_factories_path
        @resource = resource
        @data_object = data_object
        @logger = logger
        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end

      def find_all(account:, role:)
        factories = @resource.visible_to(role).where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:#{@policy_factories_path}/%"
          )
        ).order(:resource_id).all
          .select { |factory| role.allowed_to?(:execute, factory) }
          .select { |factory| factory_version(factory.id).positive? }
          .group_by do |item|
            # form is: 'conjur/factories/core/v1/groups'
            _, _, classification, _, factory = item.resource_id.split('/')
            [classification, factory].join('/')
          end
          .map do |_, versions|
            versions.max { |a, b| factory_version(a.id) <=> factory_version(b.id) }
          end
          .map do |factory|
            response = secret_to_data_object(factory)
            response.result if response.success?
          end
          .compact

        if factories.empty?
          return @failure.new(
            'Role does not have permission to use Factories, or, no Factories are available',
            status: :forbidden
          )
        end

        @success.new(factories)
      end

      def find(kind:, id:, account:, role: nil, version: nil)
        factory = if version.present?
          @resource["#{account}:variable:#{@policy_factories_path}/#{kind}/#{version}/#{id}"]
        else
          @resource.where(
            Sequel.like(
              :resource_id,
              "#{account}:variable:#{@policy_factories_path}/#{kind}/%"
            )
          ).all
            .select { |item| item.resource_id.split('/').last == id }
            .select { |item| factory_version(item.id).positive? }
            .max { |a, b| factory_version(a.id) <=> factory_version(b.id) }
        end

        resource_id = "#{kind}/#{version || 'v1'}/#{id}"

        if factory.blank?
          @failure.new(
            { resource: resource_id, message: 'Requested Policy Factory does not exist' },
            status: :not_found
          )
        # Allows us to retrieve a factory for role that does not have permission to view
        # the factory. This should only be used to retrieve the schema for a factory on a
        # GET request.
        elsif role && !role.allowed_to?(:execute, factory)
          @failure.new(
            { resource: resource_id, message: 'Requested Policy Factory is not available' },
            status: :forbidden
          )
        else
          secret_to_data_object(factory)
        end
      end

      # This method is public simply for testing purposes. It allows us to convert
      # the encoded factory into a data object.
      def convert_to_data_object(encoded_factory:, classification:, version:, id:)
        decoded_factory = JSON.parse(Base64.decode64(encoded_factory))
        @success.new(
          @data_object.new(
            policy: Base64.decode64(decoded_factory['policy']),
            policy_branch: decoded_factory['policy_branch'],
            schema: decoded_factory['schema'],
            version: version,
            name: id,
            classification: classification
          )
        )
      rescue => e
        @logger.error("Error decoding factory: #{e.message}")
        @failure.new("Failed to decode Factory: '#{id}'", exception: e, status: :service_unavailable)
      end

      private

      def secret_to_data_object(variable)
        _, _, classification, version, id = variable.resource_id.split('/')
        factory = variable.secret&.value
        if factory
          convert_to_data_object(
            encoded_factory: factory,
            classification: classification,
            version: version,
            id: id
          ).bind do |data_object|
            @success.new(data_object)
          end
        else
          @failure.new(
            { resource: "#{classification}/#{version}/#{id}", message: 'Requested Policy Factory is not available' },
            status: :bad_request
          )
        end
      end

      def factory_version(factory_id)
        version_match = factory_id.match(%r{/v(\d+)/[\w-]+})
        return 0 if version_match.nil?

        version_match[1].to_i
      end
    end
  end
end
