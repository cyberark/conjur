# Represents the contract of a class that implements an rotator.
#
module Rotation
  class RotatorClass

    # Represents the rules any rotator class must conform to
    #
    class Validation

      DoesntEndWithRotator = ::Util::ErrorClass.new(
        "'{0}' is not a valid rotator, because it doesn't end in 'Rotator'"
      )

      NewValuesMethodNotPresent = ::Util::ErrorClass.new(
        "'{0}' is not a valid rotator, because it does not have " +
        "a `:new_values` method."
      )

      def initialize(cls)
        @cls = cls
      end

      def valid?
        valid_name? && valid_interface?
      end

      def validate!
        raise DoesntEndWithRotator, own_name unless valid_name?
        raise NewValuesMethodNotPresent, own_name unless valid_interface?
      end

      private

      def valid_name?
        own_name =~ /Rotator$/
      end

      def valid_interface?
        @cls.method_defined?(:new_values)
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

    # Creates a new instance of the rotator class, and adds a "null"
    # implementation of :required_variables method, if none exists
    #
    def instance
      @cls.new.tap do |inst|
        unless inst.respond_to?(:required_variables)
          def inst.required_variables; [] end
        end
      end
    end

    def name_aware
      @name_aware ||= ::Util::NameAwareModule.new(@cls)
    end

  end
end
