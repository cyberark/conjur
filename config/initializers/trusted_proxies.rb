# frozen_string_literal: true

Rails.application.configure do
  # Only disable the trusted proxies cache if the config attribute exists and is
  # truthy.
  disable_cache = config.respond_to?(:conjur_disable_trusted_proxies_cache) &&
    config.conjur_disable_trusted_proxies_cache

  Rack::Request.ip_filter = Conjur::IsIpTrusted.new(
    config: Rails.application.config.conjur_config,
    disable_cache: disable_cache
  )
end
