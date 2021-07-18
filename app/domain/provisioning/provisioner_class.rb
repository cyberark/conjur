# frozen_string_literal: true

# Represents a class that implements an authenticator.
#
module Provisioning
  class ProvisionerClass

    # Represents the rules any provisioner class must conform to
    #
    class Validation

      Err = Errors::Provisioning::ProvisionerClass
      # Possible Errors Raised:
      # NotNamedProvisioner, MissingProvisionMethod

      def initialize(cls)
        @cls = cls
      end

      def valid?
        valid_name? && valid_interface?
      end

      def provides_login?
        @cls.method_defined?(:login)
      end

      def validate!
        raise Err::NotNamedProvisioner, own_name unless valid_name?
        raise Err::MissingProvisionMethod, own_name unless valid_interface?
      end

      private

      def valid_name?
        own_name == 'Provisioner'
      end

      def valid_interface?
        @cls.method_defined?(:provision)
      end

      def own_name
        name_aware.own_name
      end

      def name_aware
        @name_aware ||= ::Util::NameAwareModule.new(@cls)
      end

    end

    attr_reader :provisioner

    def initialize(cls)
      Validation.new(cls).validate!
      @cls = cls
    end

    def annotation_name
      name_aware.parent_name.underscore.dasherize
    end

    def name_aware
      @name_aware ||= ::Util::NameAwareModule.new(@cls)
    end
  end
end
