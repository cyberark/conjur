module Rotation
  class MasterRotator

    RotatorNotFound = ::Util::ErrorClass.new(
      "'{0}' is not an installed rotator"
    )

    # We inject both the rotation_model and the secret_model to ease unit
    # testing, and also because, even though the rotation query code was thrown
    # into Secret, it should probably be refactored out into its own model
    # class.  When that's done, it will require only a one word change here.
    #
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

        new_values = rotator.new_values(new_values_input(rotator))
        update_all_secrets(new_values, secret['ttl'])
      end
    end

    private

    def new_values_input(rotator)
      resource_ids = resource_ids(rotator.required_variables)
      secret_model
        .latest_resource_values(resource_ids)
        .map { |x| [variable_name(x.resource_id), x.value] }
        .to_h
    end

    # The rotator returns us a Hash of {resource_id: new_value} pairs
    # (new_values) that represent a group of related variables which all
    # require rotation.  Since we want to treat them as a unit, we do the
    # update inside a transaction.
    #
    def update_all_secrets(new_values, ttl)
      Sequel::Model.transaction do
        new_values.each do |resource_id, value|
          update_secret(resource_id, value, ttl)
        end
      end
    end

    def update_secret(resource_id, value, ttl)
      secret_model.create(
        resource_id: resource_id,
        expires_at: ISO8601Duration.new(ttl).from_now,
        value: value
      )
    end

    def required_variables(rotator)
      rotator.respond_to?(:required_variables) ?
        rotator.required_variables : []
    end

    def variable_name(resource_id)
      resource_id.split(':', 3).last
    end

    def resource_ids(variable_names)
      variable_names.map { |name| resource_id(name) }
    end

    def resource_id(variable_name)
      "#{@account}:variable:#{variable_name}"
    end

  end
end
__END__
Recall each rotator has a `required_variables` method by which it can specify the hash of `{variable_id => value }` that will be passed to its `rotate` method.  the variable ids are resource ids of the form `<acct>:<kind>:<id>`.  but where does `<acct>` come from?  clearly we don't want to hard code it into the rotator.  but since the rotator is just run when the server boots up, there isn't (i don't think?) a logged in acct to asssociate with.  so i'm confused how this work.
