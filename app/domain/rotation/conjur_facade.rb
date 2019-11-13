# frozen_string_literal: true

module Rotation

  # This class is the only API that the rotators are provided with.
  #
  # Any updates to the Conjur database occur through here.
  #
  # A new instance is created each time a rotator is run and passed to its
  # `rotate` method, because we have to allow for the possibility that the ttl
  # of the `RotatedVariable` has changed.
  #
  class ConjurFacade

    attr_reader :rotated_variable

    def initialize(rotated_variable:,
                   secret_model: Secret,
                   resource_model: Resource,
                   db: Sequel::Model.db)
      @rotated_variable = rotated_variable
      @secret_model = secret_model
      @resource_model = resource_model
      @db = db
    end

    def current_values(variable_ids)
      @secret_model.current_values(variable_ids)
    end

    def annotations
      @resource_model.annotations(@rotated_variable.resource_id)
    end

    # new_values is a Hash of {resource_id: new_value} pairs that represent a
    # group of related variables which all require rotation.  Since we want
    # to treat them as a unit, we do the update inside a transaction.
    #
    # Additionally, the rotator may pass a block of code that it wants executed
    # inside the same transaction.  If that code errors, everything will
    # rollback.
    #
    # Eg, a database password rotator needs to both update conjur with its new
    # value, and update the database itself.  These two updates must succeed or
    # fail as a unit.
    #
    def update_variables(new_values, &rotator_code)
      @db.transaction do
        new_values.each do |resource_id, value|
          update_secret(resource_id, value)
        end
        rotator_code.call if rotator_code
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
