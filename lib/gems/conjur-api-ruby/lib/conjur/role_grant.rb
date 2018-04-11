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
  # Represents the membership of a role. `RoleGrant`s are returned
  # by {ActsAsRole#members} and represent members of the role on which the method was invoked.
  #
  # @example
  #   alice.members.map{|grant| grant.member}.include? admin_role # => true
  #   admin_role.members.map{|grant| grant.member}.include? alice # => true
  #
  class RoleGrant
    extend BuildObject::ClassMethods
    extend Cast

    # The role which was granted.
    # @return [Conjur::Role]
    attr_reader :role

    # The member role in the relationship
    # @return [Conjur::Role]
    attr_reader :member

    # When true, the role {#member} is allowed to give this grant to other roles
    #
    # @return [Boolean]
    attr_reader :admin_option

    # @api private
    #
    # Create a new RoleGrant instance.
    #
    # @param [Conjur::Role] member the member to which the role was granted
    # @param [Boolean] admin_option whether `member` can give the grant to other roles
    def initialize role, member, admin_option
      @role = role
      @member = member
      @admin_option = admin_option
    end

    # Representation of the role grant as a hash.
    def to_h
      {
        role: role.id,
        member: member.id,
        admin_option: admin_option
      }
    end
    
    def to_s
      to_h.to_s
    end

    def as_json options = {}
      to_h.as_json(options)
    end

    class << self
      # @api private
      #
      # Create a `RoleGrant` from a JSON respnose
      #
      # @param [Hash] json the parsed JSON response
      # @param [Hash] credentials the credentials used to create APIs for the member and grantor role objects
      # @return [Conjur::RoleGrant]
      def parse_from_json(json, credentials)
        role = build_object(json['role'], credentials, default_class: Role)
        member = build_object(json['member'], credentials, default_class: Role)
        RoleGrant.new(role, member, json['admin_option'])
      end
    end
  end
end
