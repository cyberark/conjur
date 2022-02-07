# frozen_string_literal: true

require 'iso8601'

module Rotation
  class MasterRotator

    # We inject both the rotation_model and the secret_model to ease unit
    # testing, and also because, even though the rotation query code was thrown
    # into Secret, it should probably be refactored out into its own model
    # class.  When that's done, it will require only a one word change here.
    #
    def initialize(
      avail_rotators:,
      rotation_model: ::Secret,
      secret_model: ::Secret,
      facade_cls: ::Rotation::ConjurFacade
    )
      @avail_rotators = avail_rotators
      @rotation_model = rotation_model
      @secret_model = secret_model
      @facade_cls = facade_cls

      Sequel::Model.db.extension(:pg_advisory_locking)
    end

    def rotate_every(seconds)
      loop do
        rotate_all
        sleep(seconds)
      end
    end

    def rotate_all
      # Attempt an advisory lock to prevent other servers from trying to rotate
      # at the same time or immediately after another server rotated the secret.
      # The same `id` needs to be used across all servers talking to the same
      # database, but can be any unused integer.
      id = Rails.configuration.rotator_lock_name.to_i(36)
      Sequel::Model.db.try_advisory_lock(id) do
        scheduled_rotations.each(&:run)
      end
    end

    private

    def scheduled_rotations
      @rotation_model.scheduled_rotations.map do |rotation|
        rotated_var = ::Rotation::RotatedVariable.new(**rotation)
        facade = @facade_cls.new(rotated_variable: rotated_var)

        ScheduledRotation.new(
          facade: facade,
          avail_rotators: @avail_rotators,
          secret_model: @secret_model
        )
      end
    end

    class ScheduledRotation
      RotatorNotFound = ::Util::ErrorClass.new(
        "'{0}' is not an installed rotator"
      )

      def initialize(avail_rotators:, facade:, secret_model:)
        @avail_rotators = avail_rotators
        @facade = facade
        @secret_model = secret_model
        validate!
      end

      def run
        rotator.rotate(@facade)
      rescue => e
        set_retry_expiration
        log_error(e)
      end

      private

      def validate!
        raise RotatorNotFound, rotator_name unless rotator
      end

      def set_retry_expiration
        @secret_model.update_expiration(resource_id, retry_expiration)
      end

      def retry_expiration
        next_exp = ::Rotation::NextExpiration.new(@facade.rotated_variable)
        next_exp.after_error
      end

      def log_error(e)
        # TODO: add to audit log (separate story)
      end

      def resource_id
        @facade.rotated_variable.resource_id
      end

      def rotator_name
        @facade.rotated_variable.rotator_name
      end

      def rotator
        @avail_rotators[rotator_name]
      end
    end

  end
end
