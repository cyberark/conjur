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
require 'conjur/host_factory_token'

module Conjur
  # A Host Factory is a way to allow clients to create Conjur hosts without giving them
  # any other access to Conjur.
  #
  # Each Host Factory can have 0 or more tokens, each of which is a random string that
  # has an associated expiration and optional CIDR restriction. A user or machine who has
  # a host factory token can use it to create new hosts, or to rotate the API keys of 
  # existing hosts.
  #
  # @see API#host_factory_create_host
  # @see HostFactoryToken
  class HostFactory < BaseObject
    include ActsAsRolsource
    
    # Create one or more host factory tokens. Each token can be used to create
    # hosts, using {API#host_factory_create_host}. 
    #
    # @param expiration [Time] the future time at which the token will stop working.
    # @param count [Integer] the number of (identical) tokens to create (default: 1).
    # @param cidr [String] a CIDR restriction on the usage of the token.
    # @return [Array<HostFactoryToken>] the token or tokens.
    def create_tokens expiration, count: 1, cidr: nil
      options = {}
      options[:expiration] = expiration.iso8601
      options[:host_factory] = id
      options[:count] = count
      options[:cidr] = cidr if cidr
      response = JSON.parse url_for(:host_factory_create_tokens, credentials, id).post(options)
      response.map do |data|
        HostFactoryToken.new data, credentials
      end
    end
    
    # Create a new token.
    #
    # @see #create_tokens
    def create_token expiration, cidr: nil
      create_tokens(expiration, cidr: cidr).first
    end

    # Enumerate the tokens on the host factory.
    #
    # @return [Array<HostFactoryToken>] the token or tokens.
    def tokens
      # Tokens list is not returned by +show+ if the caller doesn't have permission
      return nil unless self.attributes['tokens']

      self.attributes['tokens'].collect do |data|
        HostFactoryToken.new data, credentials
      end
    end
  end
end
