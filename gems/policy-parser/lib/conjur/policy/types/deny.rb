module Conjur
  module PolicyParser
    module Types
      # !deny policy entry
      class Deny < ResourceOpBase
        attribute :role, kind: :role, dsl_accessor: true
        attribute :privilege, kind: :string, dsl_accessor: true
        attribute :resource, dsl_accessor: true

        def delete_statement? 
          true 
        end

        def to_s
          "Deny #{role} to '#{privilege}' #{resource}"
        end
      end
    end
  end
end
