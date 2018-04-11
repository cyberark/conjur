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

  # This module provides methods for things that have an associated {Conjur::Role}.
  #
  # All high level Conjur assets (groups and users, for example) are composed of both a role and a resource.  This allows
  # these assets to have permissions on other assets, and for other assets to have permission
  # on them.
  #
  # The {Conjur::ActsAsRole} module itself should be considered private, but it's methods are
  # public when added to a Conjur asset class.
  module ActsAsRole
    
    # Login name of the role. This is formed from the role kind and role id.
    # For users, the role kind can be omitted.
    def login
      [ kind, identifier ].delete_if{|t| t == "user"}.join('/')
    end

    # Check whether this object exists by performing a HEAD request to its URL.
    #
    # This method will return false if the object doesn't exist.
    #
    # @example
    #   does_not_exist = api.user 'does-not-exist' # This returns without error.
    #
    #   # this is wrong!
    #   owner = does_not_exist.members # raises RestClient::ResourceNotFound
    #
    #   # this is right!
    #   owner = if does_not_exist.exists?
    #     does_not_exist.members
    #   else
    #     nil # or some sensible default
    #   end
    #
    # @return [Boolean] does it exist?
    def exists?
      begin
        rbac_role_resource.head
        true
      rescue RestClient::Forbidden
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end

    # Find all roles of which this role is a member.  By default, role relationships are recursively expanded,
    # so if `a` is a member of `b`, and `b` is a member of `c`, `a.all` will include `c`.
    #
    # ### Permissions
    # You must be a member of the role to call this method.
    #
    # You can restrict the roles returned to one or more role ids.  This feature is mainly useful
    # for checking whether this role is a member of any of a set of roles.
    #
    # ### Options
    #
    # * **recursive** Defaults to +true+, performs recursive expansion of the memberships.
    #
    # @example Show all roles of which `"conjur:group:pubkeys-1.0/key-managers"` is a member
    #   # Add alice to the group, so we see something interesting
    #   key_managers = api.group('pubkeys-1.0/key-managers')
    #   key_managers.add_member api.user('alice')
    #
    #   # Show the memberships, mapped to the member ids.
    #   key_managers.role.all.map(&:id)
    #   # => ["conjur:group:pubkeys-1.0/admin", "conjur:user:alice"]
    #
    # @example See if role `"conjur:user:alice"` is a member of either `"conjur:groups:developers"` or `"conjur:group:ops"`
    #   is_member = api.role('conjur:user:alice').all(filter: ['conjur:group:developers', 'conjur:group:ops']).any?
    #
    # @param [Hash] options options for the request
    # @return [Array<Conjur::Role>] Roles of which this role is a member
    def memberships options = {}
      request = if options.delete(:recursive) == false
        options["memberships"] = true
      else
        options["all"] = true
      end
      if filter = options.delete(:filter)
        filter = [filter] unless filter.is_a?(Array)
        options["filter"] = filter.map{ |obj| cast_to_id(obj) }
      end

      result = JSON.parse(rbac_role_resource[options_querystring options].get)
      if result.is_a?(Hash) && ( count = result['count'] )
        count
      else
        host = Conjur.configuration.core_url
        result.collect do |item|
          if item.is_a?(String)
            build_object(item, default_class: Role)
          else
            RoleGrant.parse_from_json(item, self.options)
          end
        end
      end
    end
    
    # Fetch the direct members of this role. The results are *not* recursively expanded).
    #
    # ### Permissions
    # You must be a member of the role to call this method.
    # 
    # @param options [Hash, nil] extra parameters to pass to the webservice method.
    # @return [Array<Conjur::RoleGrant>] the role memberships
    # @raise [RestClient::Forbidden] if you don't have permission to perform this operation
    def members options = {}
      options["members"] = true
      result = JSON.parse(rbac_role_resource[options_querystring options].get)
      if result.is_a?(Hash) && ( count = result['count'] )
        count
      else
        parser_for(:members, credentials, result)
      end
    end

    private

    # RestClient::Resource for RBAC role operations.
    def rbac_role_resource
      url_for(:roles_role, credentials, id)    
    end
  end
end