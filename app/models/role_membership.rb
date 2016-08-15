class RoleMembership < Sequel::Model
  unrestrict_primary_key
  
  many_to_one :member,  class: :Role
  many_to_one :role,    class: :Role
  
  def as_json options = {}
    super(options).tap do |response|
      response["role"] = response.delete("role_id")
      response["member"] = response.delete("member_id")
    end
  end
end
