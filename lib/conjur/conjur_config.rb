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
      trusted_proxies: (ENV['TRUSTED_PROXIES'] || "")
    )

    # Perform validations and collect errors then report results as exception
    on_load do
      invalid = []

      invalid << "trusted_proxies" unless trusted_proxies_valid?

      unless invalid.empty?
        raise Errors::Conjur::InvalidConfigValues, invalid.join(', ')
      end
    end

    # Get attribute sources without including attribute values
    def attribute_sources
      to_source_trace.map { |k,v| [ k.to_sym, v[:source][:type] ] }.to_h
    end

    private

    def trusted_proxies_valid?
      trusted_proxies.split(',').each do |cidr|
        IPAddr.new(cidr)
      end

      true
    rescue
      false
    end
  end
end
