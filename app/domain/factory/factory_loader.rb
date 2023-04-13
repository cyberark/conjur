# frozen_string_literal: true

module Factory
  class FactoryLoader
    def initialize(success: SuccessResponse, failure: FailureResponse, resource: Resource)
      @success = success
      @failure = failure
      @resource = resource
    end

    def load(kind:, id:, account:, current_user:)
      factory_resource = @resource["#{account}:variable:conjur/factories/#{kind}/#{id}"]
      if factory_resource.blank?
        return @failure.new(
          "Policy Factory '#{kind}/#{id}' does not exist in account '#{account}'",
          status: :not_found
        )
      end

      if current_user.allowed_to?(:execute, factory_resource)
        if factory_resource.secret.present?
          @success.new(factory_resource.secret.value)
        else
          @failure.new(
            "Policy Factory '#{kind}/#{id}' in account '#{account}' has not been initialized",
            status: :bad_request
          )
        end
      else
        @failure.new(
          "Role '#{current_user}' does not have access to Policy Factory '#{kind}/#{id}' does not exist in account '#{account}'",
          status: :forbidden
        )
      end
    end
  end
end
