module Rotation
  class MasterRotator


    # We inject both the rotation_model and the secret_model to ease unit
    # testing, and also because, even though the rotation query code was thrown
    # into Secret, it should probably be refactored out into its own model
    # class.  When that's done, it will require only a one word change here.
    #
    def initialize(avail_rotators:,
                   rotation_model: Secret,
                   secret_model: Secret)
      @avail_rotators = avail_rotators
      @rotation_model = rotation_model
      @secret_model = secret_model
    end

    def rotate_every(seconds)
      loop do
        rotate_all
        sleep(seconds)
      end
    end

    # We query the rotation model for that annotated_resource
    def rotate_all
      # Parallel.each(scheduled_rotations, in_threads: 10) do |rotation|
      #   update_all_secrets(rotation.new_values, rotation.ttl)
      # end
      scheduled_rotations.each do |rotation|
        update_all_secrets(rotation.new_values, rotation.ttl)
      end
    end

    private

    def scheduled_rotations
      @rotation_model.scheduled_rotations.map do |rotation|
        p 'scheduled_rotations', rotation
        ScheduledRotation.new(rotation.merge({
          avail_rotators: @avail_rotators,
          secret_model: @secret_model
        }))
      end
    end

    # The rotator returns us a Hash of {resource_id: new_value} pairs
    # (new_values) that represent a group of related variables which all
    # require rotation.  Since we want to treat them as a unit, we do the
    # update inside a transaction.
    #
    def update_all_secrets(new_values, ttl)
      Sequel::Model.db.transaction do
        new_values.each do |resource_id, value|
          puts "Updating #{resource_id} to #{value}.  ttl = #{ttl}"
          update_secret(resource_id, value, ttl)
        end
      end
    end

    def update_secret(resource_id, value, ttl)
      @secret_model.create(
        resource_id: resource_id,
        expires_at: ISO8601Duration.new(ttl).from_now,
        value: value
      )
    end
  end
end
