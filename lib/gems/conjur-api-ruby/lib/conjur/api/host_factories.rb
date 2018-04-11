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
require 'conjur/host_factory'

module Conjur
  class API
    #@!group Host Factory

    class << self
      # Use a host factory token to create a new host. Unlike most other methods, this
      # method does not require a Conjur access token. The host factory token is the
      # authentication and authorization to create the host.
      #
      # The token must be valid. The host id can be a new host, or an existing host. 
      # If the host already exists, the server verifies that its layer memberships
      # match the host factory exactly. Then, its API key is rotated and returned with
      # the response.
      # 
      # @param [String] token the host factory token.
      # @param [String] id the id of a new or existing host.
      # @param options [Hash] additional host creation options.
      # @return [Host]
      def host_factory_create_host token, id, options = {}
        token = token.token if token.is_a?(HostFactoryToken)
        response = url_for(:host_factory_create_host, token).post(options.merge(id: id)).body
        attributes = JSON.parse(response)
        Host.new(attributes['id'], {}).tap do |host|
          host.attributes = attributes
        end
      end
      
      # Revokes a host factory token. After revocation, the token can no longer be used to 
      # create hosts.
      # 
      # @param [Hash] credentials authentication credentials of the current user.
      # @param [String] token the host factory token.
      def revoke_host_factory_token credentials, token
        url_for(:host_factory_revoke_token, credentials, token).delete
      end
    end
    
      # Revokes a host factory token. After revocation, the token can no longer be used to 
      # create hosts.
      # 
      # @param [String] token the host factory token.
    def revoke_host_factory_token token
      self.class.revoke_host_factory_token credentials, token
    end

    #@!endgroup
  end
end
