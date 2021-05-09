Sequel.migration do
  up do
    # Remove orphan secret so turning its resource ID to foreign key will work
    execute <<-DELETE
      DELETE FROM secrets
      WHERE NOT EXISTS (
        SELECT 1 FROM resources
        WHERE secrets.resource_id = resource_id
      )
    DELETE
    # Create cascade delete relationship between resource and secret so when resource deleted its secrets are deleted too
    alter_table :secrets do
      add_foreign_key [:resource_id], :resources, on_delete: :cascade
      add_index :resource_id
    end
  end

  down do
    alter_table :secrets do
      drop_foreign_key [:resource_id]
      drop_index :resource_id
    end
  end
end
