module DB
  module Repository
    class VariablesRepository
      def initialize(
        resource_repository: ::Resource,
        logger: Rails.logger
      )
        @resource_repository = resource_repository
        @logger = logger
      end

      def find_by_id_path(path:, account:)
        @resource_repository.where(
          Sequel.like(
            :resource_id,
            "#{account}:variable:#{path}/%"
          )
        ).eager(:secrets).all.each_with_object({}) do |variable, hash|
          hash[variable.resource_id] = variable.secret.try(:value)
        end
      end
    end
  end
end
