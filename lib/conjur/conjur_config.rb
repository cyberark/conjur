# Conjur::ConjurConfig is also used in the conjurctl executable, so we cannot
# rely on Rails autoloading to make the `Anyway::Config` constant available.
require 'anyway_config'

module Conjur
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
      authenticators: []
    )

    # Perform validations and collect errors then report results as exception
    on_load do
      invalid = []

      invalid << "trusted_proxies" unless trusted_proxies_valid?
      invalid << "authenticators" unless authenticators_valid?

      unless invalid.empty?
        raise Errors::Conjur::InvalidConfigValues, invalid.join(', ')
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
        %r{^(authn|authn-(k8s|oidc|iam|ldap|gcp|azure)(/.+)?)$}
      authenticators.all? do |authenticator|
        authenticators_regex.match?(authenticator.strip)
      end
    rescue
      false
    end
  end
end
