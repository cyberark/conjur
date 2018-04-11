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
  # This module is included in object classes that have resource behavior.
  module ActsAsResource
    # @api private
    def self.included(base)
      base.include HasAttributes
      base.include Escape
      base.extend QueryString
    end

    # The full role id of the role that owns this resource.
    #
    # @example
    #   api.current_role # => 'conjur:user:jon'
    #   resource = api.create_resource 'conjur:example:resource-owner'
    #   resource.owner # => 'conjur:user:jon'
    #
    # @return [String] the full role id of this resource's owner.
    def owner
      build_object attributes['owner'], default_class: Role
    end

    # Check whether this object exists by performing a HEAD request to its URL.
    #
    # This method will return false if the object doesn't exist.
    #
    # @example
    #   does_not_exist = api.user 'does-not-exist' # This returns without error.
    #
    #   # this is wrong!
    #   owner = does_not_exist.owner # raises RestClient::ResourceNotFound
    #
    #   # this is right!
    #   owner = if does_not_exist.exists?
    #     does_not_exist.owner
    #   else
    #     nil # or some sensible default
    #   end
    #
    # @return [Boolean] does it exist?
    def exists?
      begin
        url_for(:resources_resource, credentials, id).head
        true
      rescue RestClient::Forbidden
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end

    # Lists roles that have a specified privilege on the resource. 
    #
    # This will return only roles of which api.current_user is a member.
    #
    # Options:
    #
    # * **offset** Zero-based offset into the result set.
    # * **limit**  Total number of records returned.
    #
    # @example
    #   resource = api.resource 'conjur:variable:example'
    #   resource.permitted_roles 'execute' # => ['conjur:user:admin']
    #   # After permitting 'execute' to user 'jon'
    #   resource.permitted_roles 'execute' # => ['conjur:user:admin', 'conjur:user:jon']
    #
    # @param privilege [String] the privilege
    # @return [Array<String>] the ids of roles that have `privilege` on this resource.
    def permitted_roles privilege
      result = JSON.parse url_for(:resources_permitted_roles, credentials, id, privilege).get
      if result.is_a?(Hash) && ( count = result['count'] )
        count
      else
        result
      end
    end

    # True if the logged-in role, or a role specified using the :role option, has the
    # specified +privilege+ on this resource.
    #
    # @example
    #   api.current_role # => 'conjur:cat:mouse'
    #   resource.permitted_roles 'execute' # => ['conjur:user:admin', 'conjur:cat:mouse']
    #   resource.permitted_roles 'update', # => ['conjur:user:admin', 'conjur:cat:gino']
    #
    #   resource.permitted? 'update' # => false, `mouse` can't update this resource
    #   resource.permitted? 'execute' # => true, `mouse` can execute it.
    #   resource.permitted? 'update', role: 'conjur:cat:gino' # => true, `gino` can update it.
    # @param privilege [String] the privilege to check
    # @param role [String,nil] :role check whether the role given by this full role id is permitted
    #   instead of checking +api.current_role+.
    # @return [Boolean]
    def permitted? privilege, role: nil
      url_for(:resources_check, credentials, id, privilege, role)
      true
    rescue RestClient::Forbidden
      false
    rescue RestClient::ResourceNotFound
      false
    end
  end
end
