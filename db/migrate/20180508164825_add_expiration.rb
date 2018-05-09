Sequel.migration do
  change do
    add_column :resources do
      Timestamp :expires_at
    end
  end
end
