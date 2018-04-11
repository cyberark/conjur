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
require 'conjur/role'

module Conjur
  class API
    include BuildObject

    #@!group Roles

    # Return a {Conjur::Role} representing a role with the given id.  Note that the {Conjur::Role} may or
    # may not exist (see {Conjur::Exists#exists?}).
    #
    # ### Permissions
    #
    # Because this method returns roles that may or may not exist, it doesn't require any permissions to call it:
    # in fact, it does not perform an HTTP request (except for authentication if necessary).
    #
    # @example Create and show a role
    #   iggy = api.role 'cat:iggy'
    #   iggy.exists? # true
    #   iggy.members.map(&:member).map(&:id) # => ['conjur:user:admin']
    #   api.current_role.id # => 'conjur:user:admin' # creator role is a member of created role.
    #
    # @example No permissions are required to call this method
    #   api.current_role # => "user:no-access"
    #
    #   # current role is only a member of itself, so it can't see other roles.
    #   api.current_role.memberships.count # => 1
    #   admin = api.role 'user:admin' # OK
    #   admin.exists? # => true
    #   admin.members # => RestClient::Forbidden: 403 Forbidden
    #
    # @param id [String] a fully qualified role identifier
    # @return [Conjur::Role] an object representing the role
    def role id
      build_object id, default_class: Role
    end

    # Return a {Conjur::Role} object representing the role (typically a user or host) that this API instance is authenticated
    # as.  This is derived either from the `login` argument to {Conjur::API.new_from_key} or from the contents of the
    # `token` given to {Conjur::API.new_from_token} or {Conjur::API.new_from_token_file}.
    #
    # @example Current role for a user
    #   api = Conjur::API.new_from_key 'jon', 'somepassword'
    #   api.current_role.id # => 'conjur:user:jon'
    #
    # @example Current role for a host
    #   host = api.create_host id: 'exapmle-host'
    #
    #   # Host and User have an `api` method that returns an api with their credentials.  Note
    #   # that this only works with a newly created host or user, which has an `api_key` attribute.
    #   host.api.current_role.id # => 'conjur:host:example-host'
    #
    # @param [String] account the organization account 
    # @return [Conjur::Role] the authenticated role for this API instance
    def current_role account
      self.class.role_from_username self, username, account
    end

    #@!endgroup

    class << self
      # @api private
      def role_from_username api, username, account
        api.role role_name_from_username(username, account)
      end

      # @api private
      def role_name_from_username username, account
        tokens = username.split('/')
        if tokens.size == 1
          [ account, 'user', username ].join(':')
        else
          [ account, tokens[0], tokens[1..-1].join('/') ].join(':')
        end
      end
    end
  end
end
