class Permission < Sequel::Model
  unrestrict_primary_key

  many_to_one :resource, reciprocal: :permissions
  many_to_one :role

  plugin :json_id_serializer
end
