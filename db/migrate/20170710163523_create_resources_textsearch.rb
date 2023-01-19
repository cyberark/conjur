# frozen_string_literal: true

# This migration has been ported over from Conjur v3's /authz project. I had to 
# make a few changes for Conjur OSS that have been documented with comments.
Sequel.migration do
  up do
    create_table :resources_textsearch do
      Text :resource_id, primary_key: true
    end
    
    run "ALTER TABLE ONLY resources_textsearch
        ADD CONSTRAINT resources_textsearch_resource_id_fkey
        FOREIGN KEY (resource_id) REFERENCES resources(resource_id)
        ON DELETE CASCADE;"

    run "ALTER TABLE resources_textsearch ADD COLUMN textsearch tsvector;"
    run "CREATE INDEX resources_ts_index ON resources_textsearch USING gist (textsearch);"

    run "CREATE FUNCTION tsvector(resource resources) RETURNS tsvector
        LANGUAGE sql
        AS $$
        WITH annotations AS (
          SELECT name, value FROM annotations
          WHERE resource_id = resource.resource_id
        )
        SELECT
        -- id and name are A

        -- Translate chars that are not considered word separators by parser. Note that Conjur v3's /authz
        -- did not include a period here. It has been added for Conjur OSS.
        -- Note: although ids are not english, use english dict so that searching is simpler, if less strict
        setweight(to_tsvector('pg_catalog.english', translate(identifier(resource.resource_id), './-', '   ')), 'A') ||

        setweight(to_tsvector('pg_catalog.english',
          coalesce((SELECT value FROM annotations WHERE name = 'name'), '')
        ), 'A') ||

        -- other annotations are B
        setweight(to_tsvector('pg_catalog.english',
          (SELECT coalesce(string_agg(value, ' :: '), '') FROM annotations WHERE name <> 'name')
        ), 'B') ||

        -- kind is C
        setweight(to_tsvector('pg_catalog.english', kind(resource.resource_id)), 'C')
        $$;"
    
    run "CREATE FUNCTION resource_update_textsearch() RETURNS trigger
        -- The loader orchestration logic changes the search path temporarily, which causes
        -- these triggers to be unable to find the tables and functions they need. Fix this
        -- by setting the search path from the current schema each time. Added for Conjur OSS.
        SET search_path FROM CURRENT
        LANGUAGE plpgsql
        AS $resource_update_textsearch$
        BEGIN
          IF TG_OP = 'INSERT' THEN
            INSERT INTO resources_textsearch
            VALUES (NEW.resource_id, tsvector(NEW));
          ELSE
            UPDATE resources_textsearch
            SET textsearch = tsvector(NEW)
            WHERE resource_id = NEW.resource_id;
          END IF;

          RETURN NULL;
        END
        $resource_update_textsearch$;"

    run "CREATE TRIGGER resource_update_textsearch
         AFTER INSERT OR UPDATE ON resources
         FOR EACH ROW EXECUTE PROCEDURE resource_update_textsearch();"

    run "CREATE FUNCTION annotation_update_textsearch() RETURNS trigger
        -- The loader orchestration logic changes the search path temporarily, which causes
        -- these triggers to be unable to find the tables and functions they need. Fix this
        -- by setting the search path from the current schema each time. Added for Conjur OSS.
        SET search_path FROM CURRENT
        LANGUAGE plpgsql
        AS $annotation_update_textsearch$
        BEGIN
          IF TG_OP IN ('INSERT', 'UPDATE') THEN
            UPDATE resources_textsearch rts
            SET textsearch = (
              SELECT r.tsvector FROM resources r
              WHERE r.resource_id = rts.resource_id
            ) WHERE resource_id = NEW.resource_id;
          END IF;

          IF TG_OP IN ('UPDATE', 'DELETE') THEN
            UPDATE resources_textsearch rts
            SET textsearch = (
              SELECT r.tsvector FROM resources r
              WHERE r.resource_id = rts.resource_id
            ) WHERE resource_id = OLD.resource_id;
          END IF;

          RETURN NULL;
        END
        $annotation_update_textsearch$;"

    run "CREATE TRIGGER annotation_update_textsearch
         AFTER INSERT OR UPDATE OR DELETE ON annotations
         FOR EACH ROW EXECUTE PROCEDURE annotation_update_textsearch();"

    run "INSERT INTO resources_textsearch
        SELECT resource_id, resources.tsvector
        FROM resources;"
  end

  down do
    run "DROP TRIGGER annotation_update_textsearch ON annotations;"
    run "DROP FUNCTION annotation_update_textsearch();"

    run "DROP TRIGGER resource_update_textsearch ON resources;"
    run "DROP FUNCTION resource_update_textsearch();"

    run "DROP FUNCTION tsvector(resource resources);"
    
    run "DROP INDEX resources_ts_index;"
    
    drop_table :resources_textsearch
  end
end
