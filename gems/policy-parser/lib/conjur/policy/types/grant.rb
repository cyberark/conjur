module Conjur
  module PolicyParser
    module Types
      class Grant < Base
        attribute :role, dsl_accessor: true
        attribute :member

        include RoleMemberDSL
        include AutomaticRoleDSL

        def subject_id
          Array(role).map(&:id)
        end

        def to_s
          role_str   = if role.is_a?(Array)
            role.join(', ')
          else
            role
          end
          member_str = if member.is_a?(Array)
            member.map(&:role).join(', ')
          elsif member 
            member.role
          end
          admin = Array(member).map do |member|
            member&.admin
          end
          admin_str = if Array(member).count == admin.select{|admin| admin}.count
            " with admin option"
          elsif admin.any?
            " with admin options: #{admin.join(', ')}"
          end
          "Grant #{role_str} to #{member_str}#{admin_str}"
        end
      end
    end
  end
end
