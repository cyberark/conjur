class RoleMembership < Sequel::Model
  unrestrict_primary_key
  
  plugin :json_id_serializer  
  
  [:member, :role].each do |key|
    many_to_one key, class: :Role
  end
end
