# frozen_string_literal: true

Sequel.migration do
  # The primary key used to be (privilege, resource_id, role_id) which
  # is not very useful for how some queries are structured.
  # Nothing seems to search primarily by privilege; OTOH eg. visibility check
  # searches by resource_id and extracts role_id which should be possible with
  # an index only scan after this rearrangement.
  up do
    alter_table :permissions do
      drop_constraint :permissions_pkey
      add_primary_key %i[resource_id role_id privilege]
    end
  end

  down do
    alter_table :permissions do
      drop_constraint :permissions_pkey
      add_primary_key %i[privilege resource_id role_id]
    end
  end
end
