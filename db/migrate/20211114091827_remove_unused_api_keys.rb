Sequel.migration do
  up do
    # Remove api keys for non users or hosts
    execute <<-DELETE
      DELETE FROM credentials
      WHERE kind(role_id) NOT IN ('user', 'host')
    DELETE
  end

  down do
  end
end
