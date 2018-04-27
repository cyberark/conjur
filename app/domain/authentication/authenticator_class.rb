# Represents a class that implements an authenticator.
#
module Authentication
  class AuthenticatorClass

    InvalidAuthenticator = ::Util::ErrorClass.new(
      "'{0}' is not a valid authenticator class.  It must be named " +
      "'Authenticator', implement a 'valid?(input)' method, and have an " +
      "initializer which requires either no args, or a single keyword arg " +
      "named 'env', which will be passed the ENV.  Optional arguments are " +
      "also okay."
    )

    attr_reader :authenticator

    def self.valid?(cls)
      valid_name?(cls) && valid_interface?(cls)
    end

    def self.requires_env_arg?(cls)
       # cls.instance_method(:initialize).parameters.include?([:keyreq, :env])
      !cls.respond_to?(:requires_env_arg?) || cls.requires_env_arg?
    end

    def initialize(authn)
      raise InvalidAuthenticator, authn unless self.class.valid?(authn)
      @authenticator = authn
    end

    def url_name
      name_aware.parent_name.underscore.dasherize
    end

    private

    # TODO factor this validation to a subclass
    def self.valid_name?(cls)
      ::Util::NameAwareModule.new(cls).own_name == 'Authenticator'
    end

    def self.valid_interface?(cls)
      cls.method_defined?(:valid?)
      # return false unless cls.method_defined?(:valid?)
      # valid_initializer?(cls)
      # TODO add check for valid? params
    end

    # def self.valid_initializer?(cls)
    #   params = cls.instance_method(:initialize).parameters
    #   p 'params', params
    #   required = params.select { |x| [:req, :keyreq].include?(x.first) }
    #   only_env_is_required = requires_env_arg?(cls) && required.size == 1
    #   required.empty? || only_env_is_required
    # end

    def name_aware
      @name_aware ||= ::Util::NameAwareModule.new(@authenticator)
    end
  end
end
