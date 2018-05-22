module Rotation
  class MasterRotator

    class Resource
      attr_reader :id

      def initialize(resource_id)
        @id = resource_id
      end

      def account
        @id.split(':')[0]
      end

      def kind
        @id.split(':')[1]
      end

      def name
        @id.split(':', 3)[2]
      end

      def renamed(name)
        new("#{account}:#{kind}:#{name}")
      end
    end

    class ScheduledRotation

      RotatorNotFound = ::Util::ErrorClass.new(
        "'{0}' is not an installed rotator"
      )

      attr_reader :resource, :ttl, :rotator_name

      def initialize(resource_id:, ttl:, rotator_name:,
                     avail_rotators:, secret_model:)
        @resource = Resource.new(resource_id)
        @ttl = ttl
        @rotator_name = rotator_name
        @avail_rotators = avail_rotators
        @secret_model = secret_model
        validate!
      end

      def new_values
        rotator.new_values(current_values)
      end

      private

      def current_values
        @secret_model.latest_resource_values(required_resources)
      end

      def rotator
        @avail_rotators[rotator_name]
      end

      def required_resources
        rotator.required_variables.map { |var| resource.renamed(var) }
      end

      def validate!
        raise RotatorNotFound, rotator_name unless rotator
      end
    end

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
      Parallel.each(scheduled_rotations, in_threads: 10) do |rotation|
        update_all_secrets(rotation.new_values, rotation.ttl)
      end
    end

    private

    def scheduled_rotations
      @rotation_model.scheduled_rotations.map do |rotation|
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
__END__
Recall each rotator has a `required_variables` method by which it can specify the hash of `{variable_id => value }` that will be passed to its `rotate` method.  the variable ids are resource ids of the form `<acct>:<kind>:<id>`.  but where does `<acct>` come from?  clearly we don't want to hard code it into the rotator.  but since the rotator is just run when the server boots up, there isn't (i don't think?) a logged in acct to asssociate with.  so i'm confused how this work.
