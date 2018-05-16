module Rotation
  class MasterRotator

    RotatorNotFound = ::Util::ErrorClass.new(
      "'{0}' is not an installed rotator"
    )

    def initialize(rotators:, rotation_model: Secret, secret_model: Secret)
      @rotators = rotators
      @rotation_model = rotation_model
      @secret_model = secret_model
    end

    def rotate_every(seconds)
      loop do
        rotate_all
        sleep(seconds)
      end
    end

    def rotate_all
      rotations = rotation_model.required_rotations
      Parallel.each(rotations, in_threads: 10) do |secret|

        rotator = @rotators[secret['rotator']]
        raise RotatorNotFound unless rotator


        Sequel::Model.transaction do
          secret_model.create({
            resource_id: secret[:resource_id],
            expires_at: ISO8601Duration.new(secret[:ttl]).from_now,
            value: SecureRandom.hex(5),
          })
        end
      end
    end

  end
end
