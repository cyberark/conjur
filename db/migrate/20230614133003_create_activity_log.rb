# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :activity_log do
      String :activity_id, primary_key: true
      Timestamp :timestamp, null: false
    end

    self[:activity_log].insert(activity_id: 'last_slosilo_update', timestamp: 100.years.ago)
  end
end
