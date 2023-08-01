# frozen_string_literal: true

require 'json'

class Platform < Sequel::Model
  
  attr_encrypted :data, aad: :platform_id

  unrestrict_primary_key

  def as_json
    {
      id: self.platform_id,
      max_ttl: self.max_ttl,
      type: self.platform_type,
      data: JSON.parse(self.data),
      created_at: self.created_at,
      modified_at: self.modified_at
    }
  end
end
