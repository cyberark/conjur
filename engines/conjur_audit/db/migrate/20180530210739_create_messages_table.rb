# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :messages, if_not_exists: true do
      Integer :facility, null: false
      Integer :severity, null: false
      timestamptz :timestamp, null: false
      String :hostname
      String :appname
      String :procid
      String :msgid
      jsonb :sdata
      String :message, null: false
    end
  end
end
