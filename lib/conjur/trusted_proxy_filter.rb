# frozen_string_literal: true

module Conjur
  # TrustedProxyFilter wraps the default Rack IP filtering. This allows
  # the trusted proxies to be configured using the environment variable,
  # `TRUSTED_PROXIES`.
  #
  # The value of `TRUSTED_PROXIES` must be a comma-separated list of IP
  # addresses or IP address ranges using CIDR notation.
  #
  # Example: TRUSTED_PROXIES=4.4.4.4,192.168.100.0/24
  class TrustedProxyFilter
    def initialize(wrapped_filter, env: ENV, options: { disable_cache: true })
      @wrapped_filter = wrapped_filter
      @env = env
      @options = options
      @cached_trusted_proxies = nil
    end

    def call(ip)
      return @wrapped_filter.call(ip) unless trusted_proxies

      trusted_proxies.any? { |cidr| cidr.include?(ip) }
    end

    def trusted_proxies
      @cached_trusted_proxies || load_trusted_proxies_from_env
    end

    # Reek flags @env['TRUSTED_PROXIES'] as :reek:DuplicateMethodCall. Refactoring
    # this would not enhance the readability or performance.
    def load_trusted_proxies_from_env
      return nil unless @env['TRUSTED_PROXIES']

      proxy_ips = Set.new(@env['TRUSTED_PROXIES'].split(',') + ['127.0.0.1'])
        .collect { |cidr| IPAddr.new(cidr.strip) }

      @cached_trusted_proxies = proxy_ips unless @options[:disable_cache]
      proxy_ips
    end
  end
end
