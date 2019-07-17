# frozen_string_literal: true

class PolicyFactory < Sequel::Model
  include HasId

  unrestrict_primary_key

  one_to_one :role, class: :Role
  many_to_one :base_policy, class: :Resource
end

