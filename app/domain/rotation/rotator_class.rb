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

      FreshValuesMethodNotPresent = ::Util::ErrorClass.new(
        "'{0}' is not a valid rotator, because it does not have " +
        "a `:fresh_values` method."
      )

      def initialize(cls)
        @cls = cls
      end

      def valid?
        valid_name? && valid_interface?
      end

      def validate!
        raise DoesntEndWithRotator, own_name unless valid_name?
        raise FreshValuesMethodNotPresent, own_name unless valid_interface?
      end

      private

      def valid_name?
        own_name =~ /Rotator$/
      end

      def valid_interface?
        @cls.method_defined?(:fresh_values)
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

    def needs_additional_variables?
      @cls.respond_to?(:required_variables)
    end

    def annotation_name
      name_aware.parent_name.underscore.dasherize
    end

    def name_aware
      @name_aware ||= ::Util::NameAwareModule.new(@cls)
    end

  end
end
