# Reads application config from a YAML file on disk, as well as env vars
# prefixed with CONJUR_ then serves as a single point to access configuration
# from the Conjur application code.

class Conjur::ConjurConfig < Anyway::Config
  config_name :conjur

  # Env vars prefixed w/ CONJUR_ overwrite values loaded from file
  env_prefix :conjur

  attr_config(
    # Read TRUSTED_PROXIES before default to maintain backwards compatibility
    trusted_proxies: (ENV['TRUSTED_PROXIES'] || "")
  )
end
