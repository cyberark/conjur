# frozen_string_literal: true

module Util

  # provides helper methods for interacting with CIDR network addresses 
  module CIDR
    class << self

      # returns the formatted CIDR formatted string for a network
      def format_cidr cidr
        cidr.is_a?(IPAddr) ? "#{cidr}/#{cidr_mask cidr}" : cidr.to_s
      end

      # returns the length of the netmask in bits
      def cidr_mask cidr
        mask = cidr.instance_variable_get(:@mask_addr).to_s(2)[/\A(1*)0*\z/, 1]
        raise ArgumentError, "invalid IP mask in #{cidr.inspect}" if mask.nil?
        mask.length
      end
      
    end
  end
end
