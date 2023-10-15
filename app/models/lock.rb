# frozen_string_literal: true

# Sequel::Model.db.extension(:date_arithmetic)

class Lock < Sequel::Model
  unrestrict_primary_key

  def as_json
    {
      id: self.lock_id,
      owner: self.owner,
      created_at: self.created_at,
      modified_at: self.modified_at,
      expires_at: self.expires_at
    }
  end
end