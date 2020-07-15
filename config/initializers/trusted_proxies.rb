# frozen_string_literal: true

Rails.application.configure do
  # Save the original ip_filter to use as a fallback if TRUSTED_PROXIES
  # is not set.
  default_ip_filter = Rack::Request.ip_filter

  # Only disable the trusted proxies cache if the config attribute exists and is
  # truthy.
  disable_cache = config.respond_to?(:conjur_disable_trusted_proxies_cache) &&
    config.conjur_disable_trusted_proxies_cache

  Rack::Request.ip_filter = Conjur::TrustedProxyFilter.new(
    default_ip_filter,
    options: {
      disable_cache: disable_cache
    }
  )
end
