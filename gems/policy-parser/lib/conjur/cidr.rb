require 'ipaddr'

module Conjur
  class CIDR
    def initialize(cidr)
      raise "CIDR argument must be a String" unless cidr.kind_of? String

      @cidr = cidr
      @ipaddr = IPAddr.new(cidr)
    end

    def ipv4?
      @ipaddr.ipv4?
    end

    def to_s
      "#{@ipaddr}/#{@ipaddr.prefix}"
    end

    def valid_input?
      # If the netmask is 32 bits, just supplying the IP address without a mask
      # is permitted.
      return true if @ipaddr.prefix == 32 && @cidr == @ipaddr.to_s

      # IPAddr#new strips off any extra bits from the address that are to the
      # right of the netmask. So if the provided address doesn't match the
      # stripped address, the provided CIDR is invalid.
      @cidr == to_s
    end
  end
end
