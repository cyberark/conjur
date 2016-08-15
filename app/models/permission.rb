class Permission < Sequel::Model
  unrestrict_primary_key

  many_to_one :resource, reciprocal: :permissions
  many_to_one :role

  def as_json options = {}
    super(options).tap do |response|
      response["resource"] = response.delete("resource_id")
      response["role"] = response.delete("role_id")
    end
  end
end
