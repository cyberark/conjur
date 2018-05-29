require 'pg'

module Rotation

    # This class is the only API that the rotators are provided with.
    #
    # Any updates to the Conjur database occur through here.
    #
    # An instance of this facade is injected into the rotators when they are
    # created.
    class ConjurFacade
      def initialize(secret_model: Secret, db: Sequel::Model.db)
        @secret_model = secret_model
        @db = db
      end

      def current_values(variables)
        @secret_model.current_values(variables)
      end

      # new_values is a Hash of {resource_id: new_value} pairs
      # (new_values) that represent a group of related variables which all
      # require rotation.  Since we want to treat them as a unit, we do the
      # update inside a transaction.
      #
      def update_values(new_values)
        @db.transaction do
          new_values.each do |resource_id, value|
            puts "Updating #{resource_id} to #{value}.  ttl = #{ttl}"
            update_secret(resource_id, value, ttl)
          end
        end
      end

      private

      def update_secret(resource_id, value, ttl)
        @secret_model.create(
          resource_id: resource_id,
          expires_at: ISO8601Duration.new(ttl).from_now,
          value: value
        )
      end
    end

end
