# frozen_string_literal: true

class RoleMembership < Sequel::Model
  unrestrict_primary_key
  
  many_to_one :member,  class: :Role
  many_to_one :role,    class: :Role
  
  def as_json options = {}
    super(options).tap do |response|
      %w[role member policy].each do |field|
        write_id_to_json response, field
      end
    end
  end

  dataset_module do
    def member_of role_ids
      subset_roles = Set.new(role_ids.map{|id| Role[id]}.compact.map(&:role_id))
      where(member_id: subset_roles.to_a)
    end
  end
end
