# frozen_string_literal: true

require 'forwardable'

module Util
  # provides helper methods for interacting with CIDR network addresses 
  class CIDR
    extend Forwardable

    def_delegators :@ip_addr, :include?

    def initialize(ip_addr)
      @ip_addr = ip_addr
    end

    def to_s
      ip_addr.is_a?(IPAddr) ? "#{ip_addr}/#{mask}" : ip_addr.to_s
    end

    private 

    attr_reader :ip_addr

    def mask
      mask = ip_addr.instance_variable_get(:@mask_addr).to_s(2)[/\A(1*)0*\z/, 1]
      raise ArgumentError, "invalid IP mask in #{ip_addr.inspect}" if mask.nil?

      mask.length
    end
  end
end
