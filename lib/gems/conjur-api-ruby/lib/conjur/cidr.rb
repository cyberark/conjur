#
# Copyright 2013-2017 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
##
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'ipaddr'

module Conjur
  # Utility methods for CIDR network addresses
  module CIDR
    # Parse addr into an IPAddr if it's not one already, then extend it with CIDR
    # module. This will force validation and will raise ArgumentError if invalid.
    # @return [IPAddr] the address (extended with CIDR module)
    def self.validate addr
      addr = IPAddr.new addr unless addr.kind_of? IPAddr
      addr.extend self
    end

    def self.extended addr
      addr.prefixlen # validates
    end

    # Error raised when an address is not a valid CIDR network address
    class InvalidCIDR < ArgumentError
    end

    attr_reader :mask_addr

    # @return [String] the address as an "address/mask length" string
    # @example
    #     IPAddr.new("192.0.2.0/255.255.255.0").extend(CIDR).to_s == "192.0.2.0/24"
    def to_s
      [super, prefixlen].join '/'
    end

    # @return [Fixnum] the length of the network mask prefix
    def prefixlen
      unless @prefixlen
        return @prefixlen = 0 if (mask = mask_addr) == 0

        @prefixlen = ipv4? ? 32 : 128

        while (mask & 1) == 0
          mask >>= 1
          @prefixlen -= 1
        end

        if mask != ((1 << @prefixlen) - 1)
          fail InvalidCIDR, "#{inspect} is not a valid CIDR network address"
        end
      end
      return @prefixlen
    end
  end
end
