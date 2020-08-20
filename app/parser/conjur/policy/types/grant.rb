require_relative 'base'

module Conjur::PolicyParser::Types
  class Grant < Base
    attribute :role, dsl_accessor: true
    attribute :member

    include RoleMemberDSL
    include AutomaticRoleDSL

    def subject_id
      Array(role).map(&:id)
    end

    def to_s
      role_str   = if role.kind_of?(Array)
        role.join(', ')
      else
        role
      end
      member_str = if member.kind_of?(Array)
        member.map(&:role).join(', ')
      elsif member
        member.role
      end
      admin = Array(member).map do |member|
        member && member.admin
      end
      admin_str = if Array(member).count == admin.select{|admin| admin}.count
        " with admin option"
      elsif admin.any?
        " with admin options: #{admin.join(', ')}"
      end
      %Q(Grant #{role_str} to #{member_str}#{admin_str})
    end
  end
end
