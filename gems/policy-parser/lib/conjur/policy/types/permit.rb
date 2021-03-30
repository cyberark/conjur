module Conjur
  module PolicyParser
    module Types
      # !permit policy entry
      class Permit < ResourceOpBase
        attribute :role
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true

        def initialize privilege = nil
          self.privilege = privilege
        end

        def to_s
          if role.is_a?(Array)
            role_string = role.map(&:role))
            admin = false
          else
            role_string = role.role
            admin = role.admin
          end
          "Permit #{role_string} to [#{Array(privilege).join(', ')}] on #{Array(resource).join(', ')}#{admin ? ' with grant option' : ''}"
        end
      end
    end
  end
end
