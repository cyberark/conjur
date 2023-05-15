require "conjur/rack/version"
require "conjur/rack/authenticator"
require "conjur/rack/path_prefix"
require 'ipaddr'
require 'set'

module TrustedProxies
  
  def trusted_proxy?(ip)
    trusted_proxies ? trusted_proxies.any? { |cidr| cidr.include?(ip) } : super
  end
  
  def trusted_proxies
    @trusted_proxies || ENV['TRUSTED_PROXIES'].try do |proxies|
      cidrs = Set.new(proxies.split(',') + ['127.0.0.1'])
      @trusted_proxies = cidrs.collect {|cidr| IPAddr.new(cidr) }
    end
  end
  
end

module Rack
  class Request
    prepend TrustedProxies
  end
end
