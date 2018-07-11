# frozen_string_literal: true

# Represents the contract of a class that implements an rotator.
#
module Rotation
  class RotatorClass

    # Represents the rules any rotator class must conform to
    #
    class Validation

      RotateNotPresent = ::Util::ErrorClass.new(
        "'{0}' is not a valid rotator, because it does not have " +
        "a `:rotate` method."
      )

      def initialize(cls)
        @cls = cls
      end

      def valid?
        valid_interface?
      end

      def validate!
        raise RotateNotPresent, own_name unless valid_interface?
      end

      private

      def valid_interface?
        @cls.method_defined?(:rotate)
      end

      def own_name
        name_aware.own_name
      end

      def name_aware
        @name_aware ||= ::Util::NameAwareModule.new(@cls)
      end

    end

    def initialize(cls)
      Validation.new(cls).validate!
      @cls = cls
    end

    # The "annotation_name" is how the name of the rotator used in policy.yml,
    # as a variable annotation.  For example: "aws/some-variable"
    #
    def annotation_name
      qualifier = name_aware.parent_name.underscore.dasherize
      name      = name_aware.own_name.underscore.dasherize
      "#{qualifier}/#{name}"
    end

    # Creates a new instance of the rotator class
    #
    def instance
      @cls.new
    end

    def name_aware
      @name_aware ||= ::Util::NameAwareModule.new(@cls)
    end

  end
end
