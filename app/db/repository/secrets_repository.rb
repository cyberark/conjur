module DB
  module Repository
    class SecretsRepository
      def initialize(
        resource_repository: ::Resource,
        secret_repository: ::Secret,
        logger: Rails.logger,
        audit_logger: Audit.logger,
        rbac: RBAC::Permission.new
      )
        @resource_repository = resource_repository
        @secret_repository = secret_repository
        @rbac = rbac
        @logger = logger
        @audit_logger = audit_logger

        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end

      def find_all(account:, variables:, context:, policy_path: nil)
        response = {}.tap do |result|
          variables_to_resource_ids(
            account: account,
            variables: variables,
            policy_path: policy_path
          ).bind do |resource_ids|
            @resource_repository.where(resource_id: resource_ids).eager(:secrets).all.each do |variable|
              is_allowed = @rbac.permitted?(resource_id: variable.resource_id, privilege: :execute, role: context.role)
              if is_allowed.success?
                is_allowed.bind do
                  @audit_logger.log(
                    Audit::Event::Fetch.new(
                      resource_id: variable.resource_id,
                      version: nil,
                      user: context.role,
                      client_ip: context.request_ip,
                      operation: "fetch",
                      success: true
                    )
                  )

                  result[variable.resource_id.split(':')[-1]] = variable.secret&.value
                end
              else
                @audit_logger.log(
                  Audit::Event::Fetch.new(
                    resource_id: variable.resource_id,
                    version: nil,
                    user: context.role,
                    client_ip: context.request_ip,
                    operation: "fetch",
                    success: false,
                    error_message: 'Forbidden'
                  )
                )
                @logger.info("Role '#{context.role}' does not have permission to retrieve variable '#{variable.resource_id}'")
              end
            end
          end
        end
        if response.empty?
          joined_variables = variables.map{|v| [policy_path, v].compact.join('/') }.join(', ')
          @failure.new(
            'No variable secrets were found',
            status: :not_found,
            exception: Errors::Authorization::InsufficientResourcePrivileges.new(context.role.role_id, joined_variables)
          )
        else
          @success.new(response)
        end
      end

      # For the provided set of variables:
      #   - Update if variable exists and role has update permission
      #   - Skip (with audit) if the role does not have update permission
      #   - Skip (with log message) if variable does not exist
      # Method returns a success response if all variables have been updated,
      #   otherwise, it returns a failure response with an array of update responses
      def update(account:, variables:, context:, policy_path: nil)
        variables_to_resource_ids(account: account, variables: variables, policy_path: policy_path).bind do |resource_ids|
          results = resource_ids.map { |resource_id, value| update_variable(resource_id: resource_id, value: value, context: context) }
          return @success.new('Variables have been updated') if results.all?(&:success?)

          results.each do |result|
            @logger.send(result.level, result.message) unless result.success?
          end

          return @failure.new(results)
        end
      end

      private

      def update_variable(resource_id:, value:, context:)
        unless value.to_s.strip.present?
          return @failure.new(
            "Variable '#{resource_id}' has not been set. The provided value is empty.",
            level: :info
          )
        end

        variable = @resource_repository[resource_id]
        if variable.nil?
          return @failure.new("Variable '#{resource_id}' does not exist", level: :info)
        end

        permitted = @rbac.permitted?(resource_id: resource_id, privilege: :update, role: context.role)
        @secret_repository.create(resource_id: variable.id, value: value) if permitted.success?

        @audit_logger.log(
          Audit::Event::Update.new(
            resource: variable,
            user: context.role,
            client_ip: context.request_ip,
            operation: "update",
            success: permitted
          )
        )

        unless permitted.success?
          return @failure.new(
            "Role: '#{context.role.id}' does not have permission to update variable '#{variable.id}'",
            exception: Errors::Authorization::InsufficientResourcePrivileges.new(context.role.role_id, variable.id),
            status: :not_found
          )
        end

        permitted
      end

      def to_variable_id(account:, policy_path:, variable:)
        "#{account}:variable:#{[policy_path, variable].compact.join('/')}"
      end

      def variables_to_resource_ids(account:, variables:, policy_path:)
        case variables
        when Hash
          response = {}.tap do |result|
            variables.each do |variable, value|
              result[to_variable_id(account: account, policy_path: policy_path, variable: variable)] = value
            end
          end
          @success.new(response)
        when Array
          response = variables.map do |variable|
            to_variable_id(account: account, policy_path: policy_path, variable: variable)
          end
          @success.new(response)
        else
          msg = 'variables must be a Hash or Array'
          @failure.new(msg, exception: ArgumentError.new(msg))
        end
      end
    end
  end
end
