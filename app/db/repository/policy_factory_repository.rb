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
        rbac: RBAC::Permission.new,
        logger: Rails.logger,
        audit_logger: Audit.logger
      )
        @policy_factories_path = policy_factories_path
        @resource = resource
        @data_object = data_object
        @rbac = rbac
        @audit_logger = audit_logger
        @logger = logger

        @success = ::SuccessResponse
        @failure = ::FailureResponse

        @audit_klass = Audit::Event::Fetch
      end

      def find_all(account:, context:)
        factories = @resource.visible_to(context.role).where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:#{@policy_factories_path}/%"
          )
        ).order(:resource_id).all
          .select { |factory| @rbac.permitted?(resource: factory, privilege: :execute, role: context.role).success? }
          .select { |factory| factory_version(factory.id).positive? }
          .group_by do |item|
            # audit events added here to prevent an additional looping
            @audit_logger.log(
              @audit_klass.new(
                resource_id: item.resource_id,
                version: nil,
                user: context.role,
                client_ip: context.request_ip,
                operation: "fetch",
                success: true
              )
            )

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
          message = 'Role does not have permission to use Factories, or, no Factories are available'

          @audit_logger.log(
            @audit_klass.new(
              resource_id: '<unknown>',
              version: nil,
              user: context.role,
              client_ip: context.request_ip,
              operation: "fetch",
              success: false,
              error_message: message
            )
          )

          return @failure.new(message, status: :forbidden)
        end

        @success.new(factories)
      end

      def find(kind:, id:, account:, context:, version: nil, check_role_permission: true)
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
          @audit_logger.log(
            @audit_klass.new(
              resource_id: "#{account}:variable:#{@policy_factories_path}/#{resource_id}",
              version: nil,
              user: context.role,
              client_ip: context.request_ip,
              operation: "fetch",
              success: false,
              error_message: "Variable '#{@policy_factories_path}/#{resource_id}' not found in account '#{account}'"
            )
          )

          return @failure.new(
            { resource: resource_id, message: 'Requested Policy Factory does not exist' },
            status: :not_found
          )
        end
        # Allows us to retrieve a factory for role that does not have permission to view
        # the factory. This should only be used to retrieve the schema for a factory on a
        # GET request.
        if check_role_permission
          result = @rbac.permitted?(resource: factory, privilege: :execute, role: context.role)
          unless result.success?

            @audit_logger.log(
              @audit_klass.new(
                resource_id: "#{account}:variable:#{@policy_factories_path}/#{resource_id}",
                version: nil,
                user: context.role,
                client_ip: context.request_ip,
                operation: "fetch",
                success: false,
                error_message: 'Forbidden'
              )
            )

            return @failure.new(
              { resource: resource_id, message: 'Requested Policy Factory is not available' },
              status: :forbidden
            )
          end
        end
        @audit_logger.log(
          @audit_klass.new(
            resource_id: "#{account}:variable:#{@policy_factories_path}/#{resource_id}",
            version: nil,
            user: context.role,
            client_ip: context.request_ip,
            operation: "fetch",
            success: true
          )
        )

        secret_to_data_object(factory)
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
