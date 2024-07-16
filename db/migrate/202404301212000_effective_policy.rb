# frozen_string_literal: true

Sequel.migration do
  up do
    execute "CREATE OR REPLACE FUNCTION res_depth(resource_id text) RETURNS integer AS
    $$
      BEGIN
          RETURN length(resource_id)-length(replace(resource_id, '/', ''));
      END;
    $$ LANGUAGE plpgsql;
    "
  end
end
