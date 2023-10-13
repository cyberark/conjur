# frozen_string_literal: true

# Represents a class that implements an authenticator.
#
module Authentication
  module V2

    # This is a re-implementation of the original (below) to handle the
    # interface changes of the V2 interface.
    class AuthenticatorClass
      class Validation

        def initialize(cls)
          @cls = cls
        end

        def valid?
          valid_name? && valid_parent_name?
        end

        def validate!
          %w[
            Strategy
            DataObjects::Authenticator
            DataObjects::AuthenticatorContract
            DataObjects::RoleContract
          ].each do |klass|
            full_class_name = "#{@cls}::#{klass}".classify
            unless class_exists?(full_class_name)
              raise Errors::Authentication::AuthenticatorClass::V2::MissingAuthenticatorComponents, parent_name, klass
            end
          end
        end

        private

        def class_exists?(class_name)
          Module.const_get(class_name).is_a?(Class)
        rescue NameError
          false
        end

        def valid_name?
          own_name == 'V2'
        end

        def valid_parent_name?
          parent_name =~ /^Authn/
        end

        def own_name
          name_aware.own_name
        end

        def parent_name
          name_aware.parent_name
        end

        def name_aware
          @name_aware ||= ::Util::NameAwareModule.new(@cls)
        end
      end

      attr_reader :authenticator

      def initialize(cls)
        Validation.new(cls).validate!
        @cls = cls
      end

      def requires_env_arg?
        !@cls.respond_to?(:requires_env_arg?) || @cls.requires_env_arg?
      end

      def url_name
        name_aware.parent_name.underscore.dasherize
      end

      def name_aware
        @name_aware ||= ::Util::NameAwareModule.new(@cls)
      end

    end
  end
  class AuthenticatorClass

    # Represents the rules any authenticator class must conform to
    class Validation

      def initialize(cls)
        @cls = cls
      end

      def valid?
        valid_name? && valid_parent_name?
      end

      def provides_login?
        @cls.method_defined?(:login)
      end

      def validate!
        raise Errors::Authentication::AuthenticatorClass::DoesntStartWithAuthn, own_name unless valid_name?
        raise Errors::Authentication::AuthenticatorClass::NotNamedAuthenticator, parent_name unless valid_parent_name?
      end

      private

      def valid_name?
        own_name == 'Authenticator'
      end

      def valid_parent_name?
        parent_name =~ /^Authn/
      end

      def own_name
        name_aware.own_name
      end

      def parent_name
        name_aware.parent_name
      end

      def name_aware
        @name_aware ||= ::Util::NameAwareModule.new(@cls)
      end

    end

    attr_reader :authenticator

    def initialize(cls)
      Validation.new(cls).validate!
      @cls = cls
    end

    def requires_env_arg?
      !@cls.respond_to?(:requires_env_arg?) || @cls.requires_env_arg?
    end

    def url_name
      name_aware.parent_name.underscore.dasherize
    end

    def name_aware
      @name_aware ||= ::Util::NameAwareModule.new(@cls)
    end

  end
end
