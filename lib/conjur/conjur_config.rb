# Conjur::ConjurConfig is also used in the conjurctl executable, so we cannot
# rely on Rails autoloading to make the `Anyway::Config` constant available.
require 'anyway_config'

module Conjur
  # We are temporarily avoiding hooking into the application error system
  # because using it means you have to require about five classes when loading
  # config in conjurctl, which operates outside of the Rails environment and
  # does not have application code auto-loaded.
  class ConfigValidationError < StandardError; end

  # Reads application config from a YAML file on disk, as well as env vars
  # prefixed with CONJUR_ then serves as a single point to access configuration
  # from the Conjur application code.
  class ConjurConfig < Anyway::Config
    config_name :conjur

    # Env vars prefixed w/ CONJUR_ overwrite values loaded from file. Note that
    # Anyway Config caches these values at the class level and they will not be
    # picked up by a call to `reload` unless you first run `Anyway.env.clear`.
    env_prefix :conjur

    attr_config(
      # Read TRUSTED_PROXIES before default to maintain backwards compatibility
      trusted_proxies: (ENV['TRUSTED_PROXIES'] || []),
      # The maximum number of results for listing requests. The default value
      # is 0 and means that there is no limit.
      api_resource_list_limit_max: 0,
      user_authorization_token_ttl: 480, # The default TTL of User is 8 minutes
      host_authorization_token_ttl: 480, # The default TTL of Host is 8 minutes
      authenticators: []
    )

    def initialize(*args)
      super(*args)

    # If the config file is not a valid YAML document, we want
    # to raise a user-friendly ConfigValidationError rather than
    # a Psych library exception.
    rescue Psych::SyntaxError => e
      raise(
        ConfigValidationError,
        "Config file contains a YAML syntax error: #{e.message}"
      )

    # If the config file is valid YAML, but the root object is
    # not a YAML dictionary, this raises one of a number of
    # NoMethodError exceptions because AnywayConfig assumes parsing
    # the config file will result in a Ruby Hash. We capture
    # this and raise a more user-friendly error message.
    rescue NoMethodError
      raise(
        ConfigValidationError,
        "Unable to parse config file. " \
        "Please ensure that it is a valid YAML dictionary."
      )
    end

    # Perform validations and collect errors then report results as exception
    on_load do
      invalid = []

      invalid << "trusted_proxies" unless trusted_proxies_valid?
      invalid << "authenticators" unless authenticators_valid?

      unless invalid.empty?
        msg = "Invalid values for configured attributes: #{invalid.join(',')}"
        raise ConfigValidationError, msg
      end
    end

    # Get attribute sources without including attribute values
    def attribute_sources
      to_source_trace.map { |k, v| [ k.to_sym, v[:source][:type] ] }.to_h
    end

    # The Anyway config gem automatically converts a comma-separated env var to
    # a Ruby list, but converts single or zero element values to a string, i.e:
    #
    #   MY_LIST=one is parsed as a string
    #   MY_LIST=one,two,three is parsed as a list
    #
    # To address this inconsistent behavior, we use custom setters to ensure
    # list attributes are always converted to a a list type.
    # We filed an issue regarding this behavior:
    #   https://github.com/palkan/anyway_config/issues/82

    def trusted_proxies=(val)
      super(str_to_list(val)&.uniq)
    end

    def authenticators=(val)
      super(str_to_list(val)&.uniq)
    end

    private

    def str_to_list(val)
      val.is_a?(String) ? val.split(',') : val
    end

    def trusted_proxies_valid?
      trusted_proxies.each do |cidr|
        IPAddr.new(cidr)
      end

      true
    rescue
      false
    end

    def authenticators_valid?
      # TODO: Ideally we would check against the enabled authenticators
      # in the DB. However, we need to figure out how to use code from the
      # application without introducing warnings.
      authenticators_regex =
        %r{^(authn|authn-(k8s|oidc|iam|ldap|gcp|jwt|azure)(/.+)?)$}
      authenticators.all? do |authenticator|
        authenticators_regex.match?(authenticator.strip)
      end
    rescue
      false
    end
  end
end
