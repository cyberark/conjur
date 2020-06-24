# frozen_string_literal: true

# Represents a class that implements an authenticator.
#
module Authentication
  class AuthenticatorClass

    # Represents the rules any authenticator class must conform to
    class Validation

      def initialize(cls)
        @cls = cls
      end

      def valid?
        valid_name? && valid_parent_name? && valid_interface?
      end

      def provides_login?
        @cls.method_defined?(:login)
      end

      def validate!
        raise Errors::Authentication::AuthenticatorClass::DoesntStartWithAuthn, own_name unless valid_name?
        raise Errors::Authentication::AuthenticatorClass::NotNamedAuthenticator, parent_name unless valid_parent_name?
        raise Errors::Authentication::AuthenticatorClass::MissingValidMethod, own_name unless valid_interface?
      end

      private

      def valid_name?
        own_name == 'Authenticator'
      end

      def valid_parent_name?
        parent_name =~ /^Authn/
      end

      def valid_interface?
        @cls.method_defined?(:valid?)
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
