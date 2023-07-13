# frozen_string_literal: true
Dir[File.dirname(__FILE__) + '/../../app/db/preview/*.rb'].each do |file|
  require file
end

Sequel.migration do
  change do
    create_table :edges do
      String :id, primary_key: true
      String :name, unique: true, null: false
      String :ip, null: true
      String :version, null: true
      String :platform, null: true
      Timestamp :last_sync, null: true
      Timestamp :installation_date, null: true
    end
  end
end
