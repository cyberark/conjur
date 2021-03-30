module Conjur
  module PolicyParser
    module Types
      # Include another policy into the policy.
      class Include < Base
        attribute :file, kind: :string, type: String, singular: true, dsl_accessor: true
        
        def id= value
          self.file = value
        end
      end
    end
  end
end
