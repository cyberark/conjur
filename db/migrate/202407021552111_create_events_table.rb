# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :events do
      primary_key :event_id, :serial  # Use `serial` to make `event_id` auto-incrementing
      column :transaction_id, :xid8, null: false  # Define `transaction_id` as `BIGINT`
      String :event_type, null: false
      column :event_value, :jsonb, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP  # The default value for created_at is set to the current timestamp

      index [:transaction_id], name: :events_transaction_id_index
    end

    # Create the set_transaction_id function
    run <<~SQL
      CREATE OR REPLACE FUNCTION set_transaction_id()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Set the transaction_id to the current transaction ID
        NEW.transaction_id := pg_current_xact_id();
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Create the trigger to use the function before insert
    run <<~SQL
      CREATE TRIGGER before_insert_set_transaction_id
      BEFORE INSERT ON events
      FOR EACH ROW
      EXECUTE FUNCTION set_transaction_id();
    SQL
  end

  down do
    run "DROP TRIGGER before_insert_set_transaction_id ON events;"
    run "DROP FUNCTION set_transaction_id();"
    drop_table :events
  end
end
