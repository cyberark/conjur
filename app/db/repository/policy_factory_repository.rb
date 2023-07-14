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
        :description,
        keyword_init: true
      )
    end

    class PolicyFactoryRepository
      def initialize(
        data_object: DataObjects::PolicyFactory,
        resource: ::Resource,
        logger: Rails.logger
      )
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
            "#{account}:variable:conjur/factories/%"
          )
        ).all
          .select { |factory| role.allowed_to?(:execute, factory) }
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
            'Role does not have permission to use Factories',
            status: :forbidden
          )
        end

        @success.new(factories)
      end

      def find(kind:, id:, account:, role:, version: nil)
        factory = if version.present?
          @resource["#{account}:variable:conjur/factories/#{kind}/#{version}/#{id}"]
        else
          @resource.where(
            Sequel.like(
              :resource_id,
              "#{account}:variable:conjur/factories/#{kind}/%"
            )
          ).all
            .select { |i| i.resource_id.split('/').last == id }
            .max { |a, b| factory_version(a.id) <=> factory_version(b.id) }
        end

        resource_id = "#{kind}/#{version || 'v1'}/#{id}"

        if factory.blank?
          @failure.new(
            { resource: resource_id, message: 'Requested Policy Factory does not exist' },
            status: :not_found
          )
        elsif !role.allowed_to?(:execute, factory)
          @failure.new(
            { resource: resource_id, message: 'Requested Policy Factory is not available' },
            status: :forbidden
          )
        else
          secret_to_data_object(factory)
        end
      end

      private

      def factory_version(factory_id)
        version_match = factory_id.match(%r{/v(\d+)/[\w-]+})
        return 0 if version_match.nil?

        version_match[1].to_i
      end

      def secret_to_data_object(variable)
        _, _, classification, version, id = variable.resource_id.split('/')
        factory = variable.secret&.value
        if factory
          decoded_factory = JSON.parse(Base64.decode64(factory))
          @success.new(
            @data_object.new(
              policy: Base64.decode64(decoded_factory['policy']),
              policy_branch: decoded_factory['policy_branch'],
              schema: decoded_factory['schema'],
              version: version,
              name: id,
              classification: classification,
              description: decoded_factory['schema']&.dig('description').to_s
            )
          )
        else
          @failure.new(
            { resource: "#{classification}/#{version}/#{id}", message: 'Requested Policy Factory is not available' },
            status: :bad_request
          )
        end
      end
    end
  end
end
