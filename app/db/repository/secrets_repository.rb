module DB
  module Repository
    class SecretsRepository
      def initialize(
        resource_repository: ::Resource,
        secret_repository: ::Secret,
        logger: Rails.logger,
        rbac: RBAC::Permission.new
      )
        @resource_repository = resource_repository
        @secret_repository = secret_repository
        @rbac = rbac
        @logger = logger

        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end

      def find_all(account:, variables:, role:, policy_path: nil)
        response = {}.tap do |result|
          variables_to_resource_ids(
            account: account,
            variables: variables,
            policy_path: policy_path
          ).bind do |resource_ids|
            @resource_repository.where(resource_id: resource_ids).eager(:secrets).all.each do |variable|
              @rbac.permitted?(resource_id: variable.resource_id, privilege: :execute, role: role).bind do
                result[variable.resource_id.split(':')[-1]] = variable.secret&.value
              end
              @logger.info("Role '#{role}' does not have permission to retrieve variable '#{variable.resource_id}'")
            end
          end
        end
        if response.empty?
          joined_variables = variables.map{|v| [policy_path, v].compact.join('/') }.join(', ')
          @failure.new(
            'No variable secrets were found',
            status: :not_found,
            exception: Errors::Authorization::InsufficientResourcePrivileges.new(role, joined_variables)
          )
        else
          @success.new(response)
        end
      end

      def update(account:, variables:, role:, policy_path: nil)
        variables_to_resource_ids(account: account, variables: variables, policy_path: policy_path).bind do |resource_ids|
          resource_ids.each do |resource_id, value|
            permitted = @rbac.permitted?(resource_id: resource_id, privilege: :update, role: role)
            permitted.bind do
              unless value.to_s.strip.present?
                @logger.info("Variable '#{resource_id}' has not been set. The provided value is empty.")
                next
              end

              variable = @resource_repository[resource_id]
              if variable.nil?
                @logger.info("Variable '#{resource_id}' does not exist")
                next
              end

              @secret_repository.create(resource_id: variable.id, value: value)
              variable.enforce_secrets_version_limit
              next
            end
            unless permitted.success?
              return @failure.new(
                "Role '#{role}' does not have permission to set the value of '#{resource_id}'",
                status: :unauthorized,
                exception: Errors::Authorization::InsufficientResourcePrivileges.new(role, resource_id)
              )
            end
          end
          @success.new('Variables have been updated')
        end
      end

      private

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
