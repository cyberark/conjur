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
        self.class.new("#{account}:#{kind}:#{name}")
      end
    end

    class ScheduledRotation

      RotatorNotFound = ::Util::ErrorClass.new(
        "'{0}' is not an installed rotator"
      )

      attr_reader :resource, :ttl, :rotator_name

      def initialize(resource_id:, ttl:, rotator_name:,
                     avail_rotators:, secret_model:)
        @resource = ::Rotation::MasterRotator::Resource.new(resource_id)
        @ttl = ttl
        @rotator_name = rotator_name
        @avail_rotators = avail_rotators
        @secret_model = secret_model
        validate!
      end

      # Really this is a pipeline, but it's hard to express it as such in ruby:
      #
      # current_values | name_keys | new_values | resource_id_keys
      #
      def new_values
        resource_id_keys(rotator.new_values(name_keys(current_values)))
      end

      private

      def current_values
        @secret_model.latest_resource_values(required_resources)
      end

      def rotator
        @avail_rotators[rotator_name]
      end

      def required_resources
        rotator.required_variables.map { |var| resource.renamed(var).id }
      end

      def validate!
        raise RotatorNotFound, rotator_name unless rotator
      end

      def name_keys(vals_by_resource_id)
        p vals_by_resource_id
        vals_by_resource_id.map do |resource_id, val|
          [::Rotation::MasterRotator::Resource.new(resource_id).name, val]
        end.to_h
      end

      def resource_id_keys(vals_by_name)
        vals_by_name.map { |name, val| [resource.renamed(name).id, val] }.to_h
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
          puts "updating #{resource_id}, #{value}"
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
