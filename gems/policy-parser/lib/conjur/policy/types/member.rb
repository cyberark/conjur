module Conjur::PolicyParser::Types
  class Member < Base
    def initialize role = nil
      self.role = role
    end

    attribute :role
    attribute :admin, kind: :boolean, singular: true

    def to_s
      "#{role} #{admin ? 'with' : 'without'} admin option"
    end
  end
end
