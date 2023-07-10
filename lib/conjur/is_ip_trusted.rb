# frozen_string_literal: true

module Conjur
  # IsIpTrusted wraps the default Rack IP filtering. This allows
  # the trusted proxies to be configured using the environment variable,
  # `TRUSTED_PROXIES`.
  #
  # The value of `TRUSTED_PROXIES` must be a comma-separated list of IP
  # addresses or IP address ranges using CIDR notation.
  #
  # Example: TRUSTED_PROXIES=4.4.4.4,192.168.100.0/24
  class IsIpTrusted
    def initialize(config:, disable_cache: true)
      @config = config
      @disable_cache = disable_cache
      @cached_trusted_proxies = nil
      @cache_expiration = Time.at(0)

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
      return @cached_trusted_proxies if @cached_trusted_proxies and @cache_expiration >= Time.now

      # The trusted proxy IPs are `127.0.0.1` plus those defined in the
      # `TRUSTED_PROXIES` environment variable.
      proxy_ips = [IPAddr.new('127.0.0.1')] + configured_trusted_proxies + detected_trusted_proxies

      # If not disabled, cache the IP address list
      unless @disable_cache
        @cached_trusted_proxies = proxy_ips
        @cache_expiration = Time.now + 60
      end
      proxy_ips
    end

    private

    def configured_trusted_proxies
      trusted_proxies = @config.trusted_proxies

      return [] unless trusted_proxies

      Set.new(trusted_proxies)
        .map { |cidr| IPAddr.new(cidr.strip) }
    end

    def detected_trusted_proxies
      begin
        return Edge.all.map {|edge| IPAddr.new(edge.ip.strip)}
      rescue
        return []
      end
    end
  end
end
