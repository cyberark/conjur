# frozen_string_literal: true

module Authentication
  module AuthnLdap

    # Interface to load LDAP configuration variables from various
    # config value locations.
    #
    # Will attempt to load the first valid value and will fallback
    # to a default if provided.
    #
    # If a block is given, the value will be transformed by the block
    # before returning.
    class ConfigurationLoader
      class << self
        def load(*loaders, default: nil)
          value = loaders.map(&:value).find(&:present?) || default
          block_given? ? yield(value) : value
        end
      end
    end

    # Base class for loading configuration values from
    # a Conjur Webservice object
    class WebServiceLoader
      def initialize(input)
        @input = input
      end

      def webservice
        @webservice ||= ::Authentication::Webservice.new(
          account: @input.account,
          authenticator_name: @input.authenticator_name,
          service_id: @input.service_id
        )
      end
    end

    # Configuration loader for webservice annotations
    class AnnotationLoader < WebServiceLoader
      ANNOTATION_PREFIX = "ldap-authn/"

      def initialize(input, name)
        super(input)
        @name = name
      end

      def value
        webservice.annotation(ANNOTATION_PREFIX + @name)
      end
    end

    # Configuration loader for webservice variables
    class VariableLoader < WebServiceLoader
      def initialize(input, name)
        super(input)
        @name = name
      end

      def value
        webservice.variable(@name)&.secret&.value
      end
    end

    # Configuration loader for environment variables
    class EnvironmentLoader
      def initialize(env, name)
        @env = env
        @name = name
      end

      def value
        @env[@name]
      end
    end

  end
end
