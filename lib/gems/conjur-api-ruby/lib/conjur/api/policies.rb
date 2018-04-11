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
require 'conjur/policy_load_result'
require 'conjur/policy'

module Conjur
  class API
    #@!group Policy management
    
    # Append only.
    POLICY_METHOD_POST = :post
    # Allow explicit deletion statements, but don't delete implicitly delete data.
    POLICY_METHOD_PATCH = :patch
    # Replace the policy entirely, deleting any existing data that is not declared in the new policy.
    POLICY_METHOD_PUT = :put

    # Load a policy document into the server.
    #
    # The modes are support for policy loading:
    #
    # * POLICY_METHOD_POST Policy data will be added to the named policy. Deletions are not allowed.
    # * POLICY_METHOD_PATCH Policy data can be added to or deleted from the named policy. Deletions
    # are performed by an explicit `!delete` statement.
    # * POLICY_METHOD_PUT The policy completely replaces the name policy. Policy data which is present
    # in the server, but not present in the new policy definition, is deleted.
    #
    # @param id [String] id of the policy to load.
    # @param policy [String] YAML-formatted policy definition. 
    # @param account [String] Conjur organization account
    # @param method [Symbol] Policy load method to use: {POLICY_METHOD_POST} (default), {POLICY_METHOD_PATCH}, or {POLICY_METHOD_PUT}.
    def load_policy id, policy, account: Conjur.configuration.account, method: POLICY_METHOD_POST
      request = url_for(:policies_load_policy, credentials, account, id)
      PolicyLoadResult.new JSON.parse(request.send(method, policy))
    end

    #@!endgroup
  end
end
