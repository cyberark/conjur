module Rotation
  class MasterRotator

    RotatorNotFound = ::Util::ErrorClass.new(
      "'{0}' is not an installed rotator"
    )

    def initialize(rotators:,
                   account:,
                   rotation_model: Secret,
                   secret_model: Secret)
      @rotators = rotators
      @account = account
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

        fresh_values = rotator.fresh_values(fresh_values_input(rotator))

        Sequel::Model.transaction do
          fresh_values.each do |resource_id, value|
            secret_model.create(
              resource_id: resource_id,
              expires_at: ISO8601Duration.new(secret[:ttl]).from_now,
              value: value
            )
          end
        end

      end
    end

    private

    def fresh_values_input(rotator)
      resource_ids = variable_resource_ids(rotator.required_variables)
      secret_model
        .latest_resource_values(resource_ids)
        .map { |x| [x.resource_id, x.value] }
        .to_h
    end

    def variable_resource_ids(var_names)
      var_names.map { |name| "#{@account}:variable:#{name}" }
    end

  end
end
__END__
Recall each rotator has a `required_variables` method by which it can specify the hash of `{variable_id => value }` that will be passed to its `rotate` method.  the variable ids are resource ids of the form `<acct>:<kind>:<id>`.  but where does `<acct>` come from?  clearly we don't want to hard code it into the rotator.  but since the rotator is just run when the server boots up, there isn't (i don't think?) a logged in acct to asssociate with.  so i'm confused how this work.
