require 'active_support/core_ext/string'
require 'util/error_class'
require 'util/name_aware_module'

# Represents a class that implements an authenticator.
#
module Authentication
  class AuthenticatorClass

    InvalidAuthenticator = ::Util::ErrorClass.new(
      "'{0}' is not a valid authenticator class.  It must be named " +
      "'Authenticator', implement either a 'valid?(username:, password:)' " +
      "or a 'valid?(username:, password:, service_id:)' method, and have a " +
      "constructor that takes only keyword arguments"
    )

    attr_reader :authenticator

    def self.valid?(cls)
      valid_name?(cls) && valid_interface?(cls)
    end

    def initialize(authn)
      raise InvalidAuthenticator, authn unless self.class.valid?(authn)
      @authenticator = authn
    end

    def url_name
      name_aware.parent_name.underscore.dasherize
    end

    def pass_env_to_new?
      @authenticator.method(:new).parameters.map(&:last).any? { |x| x == :env }
    end

    private

    def self.valid_name?(cls)
      ::Util::NameAwareModule.new(cls).own_name == 'Authenticator'
    end

    def self.valid_interface?(cls)
      return false unless cls.respond_to(:valid?)
      return false unless keyword_only_initializer?(cls)
    end

    def self.keyword_only_initializer?(cls)
      cls.method(:new).parameters.map(&:first).all? { |x| x == :key }
    end

    def name_aware
      @name_aware ||= ::Util::NameAwareModule.new(@authenticator)
    end
  end
end
