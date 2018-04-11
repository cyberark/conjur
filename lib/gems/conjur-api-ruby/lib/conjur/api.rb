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
require 'active_support'
require 'active_support/deprecation'

require 'conjur/configuration'
require 'conjur/routing'
require 'conjur/id'
require 'conjur/base'
require 'conjur/exceptions'
require 'conjur/build_object'
require 'conjur/base_object'
require 'conjur/acts_as_resource'
require 'conjur/acts_as_role'
require 'conjur/acts_as_rolsource'
require 'conjur/acts_as_user'
require 'conjur/log_source'
require 'conjur/has_attributes'
require 'conjur/api/authn'
require 'conjur/api/roles'
require 'conjur/api/resources'
require 'conjur/api/pubkeys'
require 'conjur/api/variables'
require 'conjur/api/policies'
require 'conjur/api/host_factories'
require 'conjur/host'
require 'conjur/group'
require 'conjur/variable'
require 'conjur/layer'
require 'conjur/cache'
require 'conjur-api/version'

# Monkey patch RestClient::Request so it always uses
# :ssl_cert_store. (RestClient::Resource uses Request to send
# requests, so it sees :ssl_cert_store, too).
# @api private
class RestClient::Request
  alias_method :initialize_without_defaults, :initialize

  def default_args
    {
      ssl_cert_store: OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE
    }
  end

  def initialize args
    initialize_without_defaults default_args.merge(args)
  end
end

# @api private
class RestClient::Resource
  include Conjur::Escape
  include Conjur::LogSource

  # @api private
  # This method exists so that all {RestClient::Resource}s support JSON serialization.  It returns an
  # empty hash.
  # @return [Hash] the empty hash
  def to_json(options = {})
    {}
  end

  # Creates a Conjur API from this resource's authorization header.
  #
  # The new API is created using the token, so it will not be able to refresh
  # when the token expires (after about 8 minutes).  This is equivalent to creating
  # an {Conjur::API} instance with {Conjur::API.new_from_token}.
  #
  # @return {Conjur::API} the new api
  def conjur_api
    api = Conjur::API.new_from_token token, remote_ip: remote_ip
    api
  end

  # Get an authentication token from the clients Authorization header.
  #
  # Useful fields in the token include `"data"`, which holds the username for which the
  # token was issued, and `"timestamp"`, which contains the time at which the token was issued.
  # The token will expire 8 minutes after timestamp, but we recommend you treat the lifespan as
  # about 5  minutes to account for time differences.
  #
  # @return [Hash] the parsed authentication token
  def token
    authorization = options[:headers][:authorization]
    if authorization && authorization.to_s[/^Token token="(.*)"/]
      JSON.parse(Base64.decode64($1))
    else
      raise AuthorizationError.new("Authorization missing")
    end
  end

  def remote_ip
    options[:headers][:x_forwarded_for]
  end

  # The username this resource authenticates as.
  #
  # @return [String] the username
  def username
    options[:user] || options[:username]
  end
end
