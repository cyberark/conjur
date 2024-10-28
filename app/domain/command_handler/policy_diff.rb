# frozen_string_literal: true

# Returns the diff between the current policy and the new policy.
module CommandHandler
  class PolicyDiff
    def initialize(
      policy_repository: DB::Repository::PolicyRepository.new,
      logger: Rails.logger
    )
      @logger = logger
      @policy_repository = policy_repository

      # Defined here for visibility. We shouldn't need to mock these.
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    def call(diff_schema_name:)
      @policy_repository.find_created_elements(diff_schema_name: diff_schema_name).bind do |created|
        @policy_repository.find_deleted_elements(diff_schema_name: diff_schema_name).bind do |deleted|
          @policy_repository.find_original_elements(diff_schema_name: diff_schema_name).bind do |updated|
            return @success.new({
              created: created,
              deleted: deleted,
              updated: updated
            })
          end
        end
      end
    end
  end
end
