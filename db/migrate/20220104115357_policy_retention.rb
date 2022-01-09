Sequel.migration do
  up do
    execute <<-DELETE
      WITH
        "ordered_versions" AS (
          SELECT *, row_number() over( PARTITION BY "resource_id"
            ORDER BY "version" DESC) as row_number 
          FROM "policy_versions"
        )
      DELETE FROM "policy_versions" AS policies
      WHERE EXISTS ( 
        SELECT *
        FROM  ordered_versions
        WHERE row_number > 20 AND
              resource_id = policies.resource_id AND 
              version = policies.version)
    DELETE
  end
end
