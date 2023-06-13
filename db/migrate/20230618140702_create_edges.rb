# frozen_string_literal: true

Sequel.migration do
  change do
    def migrate_single_edge
      edge_host = Role.where(:role_id.like('conjur:host:edge/%edge-host-%')).first
      edge_installer = Role.where(:role_id.like('conjur:host:edge/%edge-installer-host-%')).first
      if edge_host && edge_installer
        Edge.insert(name: "first_edge", id: Edge.hostname_to_id(edge_host), version: "1.0.2")
      end
    end

    create_table :edges do
      column :id, :uuid, type: String, primary_key: true
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
