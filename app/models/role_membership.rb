class RoleMembership < Sequel::Model
  unrestrict_primary_key
  
  [:member, :role].each do |key|
    many_to_one key, class: :Role
  end
  
  def as_json options = {}
    super(options).tap do |response|
      response["role"] = role_id
      response["member"] = member_id
    end
  end
end
