# frozen_string_literal: true

# This migration addresses an issue highlight in this post 
# https://discuss.cyberarkcommons.org/t/database-error-after-backup-restore/474/11.
# Where a foreign key constraint leads to an internal error
Sequel.migration do
  up do
    run "CREATE OR REPLACE FUNCTION annotation_update_textsearch() RETURNS  trigger
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
            BEGIN
              UPDATE resources_textsearch rts
              SET textsearch = (
                SELECT r.tsvector FROM resources r
                WHERE r.resource_id = rts.resource_id
              ) WHERE resource_id = OLD.resource_id;
            EXCEPTION WHEN foreign_key_violation THEN
              /*
              It's possible when an annotation is deleted that the entire resource
              has been deleted. When this is the case, attempting to update the
              search text will raise a foreign key violation on the missing
              resource_id. 
              */
              RAISE WARNING 'Cannot update search text for % because it no longer exists', OLD.resource_id;
              RETURN NULL;
            END;
          END IF;

          RETURN NULL;
        END
        $annotation_update_textsearch$"
  end

  down do
    run "CREATE FUNCTION OR REPLACE annotation_update_textsearch() RETURNS trigger
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
  end
end
