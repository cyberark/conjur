# frozen_string_literal: true
Dir[File.dirname(__FILE__) + '/../../app/db/preview/*.rb'].each do |file|
  require file
end

Sequel.migration do
  change do
    def migrate_single_edge
      single_host_id = ::DB::Preview::SingleEdgeToMulti.new.find_single_host_id
      if single_host_id
        self[:edges].insert(name: "first_edge", id: single_host_id, version: "1.0.2")
      end
    end

    create_table :edges do
      String :id, primary_key: true
      String :name, unique: true, null: false
      String :ip, null: true
      String :version, null: true
      String :platform, null: true
      Timestamp :last_sync, null: true
      Timestamp :installation_date, null: true
    end

    migrate_single_edge
  end
end
