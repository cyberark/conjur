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
    def initialize(env: ENV, options: { disable_cache: true })
      @env = env
      @options = options
      @cached_trusted_proxies = nil

      # Validate the values in TRUSTED_PROXIES at creation
      validate_trusted_proxies
    end

    def call(ip)
      trusted_proxies.any? { |cidr| cidr.include?(ip) }
    end

    def validate_trusted_proxies
      # List the trusted proxies to verify that they are
      # all valid IP addresses or CIDR address ranges.
      trusted_proxies
    end

    def trusted_proxies
      return @cached_trusted_proxies if @cached_trusted_proxies

      # The trusted proxy IPs are `127.0.0.1` plus those defined in the
      # `TRUSTED_PROXIES` environment variable.
      proxy_ips = [IPAddr.new('127.0.0.1')] + env_trusted_proxies

      # If not disabled, cache the IP address list
      @cached_trusted_proxies = proxy_ips unless @options[:disable_cache]

      proxy_ips
    end

    # Reek flags @env['TRUSTED_PROXIES'] as :reek:DuplicateMethodCall. Refactoring
    # this would not enhance the readability or performance.
    def env_trusted_proxies
      return [] unless @env['TRUSTED_PROXIES']

      Set.new(@env['TRUSTED_PROXIES'].split(','))
        .collect { |cidr| parse_trusted_proxy(cidr.strip) }
    end

    def parse_trusted_proxy(cidr)
      IPAddr.new(cidr)
    rescue IPAddr::Error
      raise Errors::Conjur::InvalidTrustedProxies, cidr
    end
  end
end
