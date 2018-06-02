module Rotation

  # This class is the only API that the rotators are provided with.
  #
  # Any updates to the Conjur database occur through here.
  #
  # An instance of this facade is injected into the rotators when they are
  # created.
  #
  # A new instance is created each time was pass it to `some_rotator.rotate`,
  # because we have to allow for the possibility that the ttl of the
  # `RotatedVariable` has changed.
  #
  class ConjurFacade

    attr_reader :rotated_variable

    def initialize(rotated_variable:,
                   secret_model: Secret,
                   db: Sequel::Model.db)
      @rotated_variable = rotated_variable
      @secret_model = secret_model
      @db = db
    end

    def current_values(variables)
      @secret_model.current_values(variables)
    end

    # new_values is a Hash of {resource_id: new_value} pairs that represent a
    # group of related variables which all require rotation.  Since we want
    # to treat them as a unit, we do the update inside a transaction.
    #
    def update_values(new_values)
      @db.transaction do
        new_values.each do |resource_id, value|
          update_secret(resource_id, value)
        end
      end
    end

    private

    def update_secret(resource_id, value)
      @secret_model.create(
        resource_id: resource_id,
        expires_at: expires_at(resource_id),
        value: value
      )
    end

    # We automatically set a new expiration based on ttl, but only when the
    # variable being updated is the rotated_variable
    #
    def expires_at(resource_id)
      @rotated_variable.resource_id == resource_id ?
        next_expiration.after_success :
        nil
    end

    def next_expiration
      ::Rotation::NextExpiration.new(@rotated_variable)
    end
  end

end
