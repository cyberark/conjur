# frozen_string_literal: true

# Represents a class that implements an authenticator.
#
module Authentication
  class AuthenticatorClass

    # Represents the rules any authenticator class must conform to
    #
    class Validation

      Err = Errors::Authentication::AuthenticatorClass
      # Possible Errors Raised:
      # DoesntStartWithAuthn, NotNamedAuthenticator, MissingValidMethod

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
        raise Err::DoesntStartWithAuthn, own_name unless valid_name?
        raise Err::NotNamedAuthenticator, parent_name unless valid_parent_name?
        raise Err::MissingValidMethod, own_name unless valid_interface?
      end

      private

      def valid_name?
        valid = own_name == 'Authenticator'
        unless valid
          Rails.logger.debug("Authenticator own_name #{own_name} is not valid")
        end
        valid
      end

      def valid_parent_name?
        valid = parent_name =~ /^Authn/
        unless valid
          Rails.logger.debug("Authenticator parent_name #{parent_name} is not valid")
        end
        valid
      end

      def valid_interface?
        valid = @cls.method_defined?(:valid?)
        unless valid
          Rails.logger.debug("Authenticator class #{@cls} has no valid? method defined")
        end
        valid
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
