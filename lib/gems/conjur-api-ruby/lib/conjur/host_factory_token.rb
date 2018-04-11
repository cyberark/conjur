#
# Copyright 2013-2017 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
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
module Conjur
  class HostFactoryToken
    def initialize data, credentials
      @data = data
      @credentials = credentials
    end
    
    # Convert the object to JSON.
    #
    # Fields:
    #
    # * token
    # * expiration
    # * cidr
    def to_json(options = {})
      { token: token, expiration: expiration, cidr: cidr }
    end
  
    # Format the token as a string, using JSON format.
    def to_s
      to_json.to_s
    end
  
    # Gets the token string.
    #
    # @return [String]
    def token
      @data['token']
    end    
    
    # Gets the expiration.
    #
    # @return [DateTime]
    def expiration
      DateTime.iso8601(@data['expiration'])
    end
    
    # Gets the CIDR restriction.
    #
    # @return [String]
    def cidr
      @data['cidr']
    end

    # Revokes the token, after which it cannot be used any more.
    def revoke
      Conjur::API.revoke_host_factory_token @credentials, token
    end

    def ==(other)
      other.class == self.class &&
        other.token == self.token &&
        other.expiration == self.expiration &&
        other.cidr == self.cidr
    end

  end
end
