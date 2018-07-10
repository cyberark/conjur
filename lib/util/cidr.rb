# frozen_string_literal: true

require 'forwardable'

module Util
  # provides helper methods for interacting with CIDR network addresses 
  class CIDR
    extend Forwardable

    def_delegators :@cidr, :include?

    def initialize(ip_addr)
      @cidr = ip_addr
    end

    def to_s
      cidr.is_a?(IPAddr) ? "#{cidr}/#{mask}" : cidr.to_s
    end

    private 

    attr_reader :cidr

    def mask
      mask = cidr.instance_variable_get(:@mask_addr).to_s(2)[/\A(1*)0*\z/, 1]
      raise ArgumentError, "invalid IP mask in #{cidr.inspect}" if mask.nil?
      mask.length
    end
  end
end
