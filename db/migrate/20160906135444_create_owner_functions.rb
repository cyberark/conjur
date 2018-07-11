# frozen_string_literal: true

Sequel.migration do
  up do
    execute Functions.ownership_trigger_sql
  end

  down do
    execute <<-SQL_CODE
    DROP FUNCTION delete_role_membership_of_owner_trigger() CASCADE;
    DROP FUNCTION update_role_membership_of_owner_trigger() CASCADE;
    DROP FUNCTION grant_role_membership_to_owner_trigger() CASCADE;
    DROP FUNCTION grant_role_membership_to_owner(text, text);
    DROP FUNCTION delete_role_membership_of_owner(text, text);

    SQL_CODE
  end
end
