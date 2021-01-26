# frozen_string_literal: true

Sequel.migration do
  # Adding a new index to the messages audit database table allows queries
  # filtering on these values to potentially leverage the index rather than
  # depend on sequential table scans.
  #
  # The fields included are based on the queries defined in the audit engine here:
  # https://github.com/cyberark/conjur/blob/master/engines/conjur_audit/app/models/conjur_audit/message.rb#L27
  #
  # NOTE: Due to the statistical nature of the Postgres query planner and the
  # storage characteristics of JSON column data, the impact of this index isn't
  # predictable or guaranteed to consistently improve the query performance for
  # all audit queries.
  up do
    execute(<<~SQL)
      CREATE INDEX messages_timestamp_sdata_entity_idx on messages (
        -- Entity queries are always sorted by descending timestamp to retrieve
        -- the most recent audit events.
        timestamp desc,
      
        -- Index the structured data fields that are used to store Resources IDs
        (sdata #>> '{subject@43868, resource}'),
        (sdata #>> '{auth@43868, service}'),
        (sdata #>> '{policy@43868, policy}'),
        
        -- Index the structured data fields that are used to Role IDs
        (sdata #>> '{subject@43868, role}'),
        (sdata #>> '{subject@43868, member}'),
        (sdata #>> '{auth@43868, user}')
      );
    SQL
  end

  down do
    execute(<<~SQL)
      DROP INDEX IF EXISTS messages_timestamp_sdata_entity_idx;
    SQL
  end
end
