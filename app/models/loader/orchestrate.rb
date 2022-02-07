# frozen_string_literal: true

# Loads a policy into the database, by operating on a PolicyVersion which has already been created with the policy id, 
# policy text, the authenticated user, and the policy owner. The PolicyVersion also parses the policy
# and checks it for syntax errors, before this code is invoked.
#
# The algorithm works by loading the policy into a new, temporary schema (schemas are lightweight namespaces
# in Postgres). Then this "new" policy (in the temporary schema) is merged into the "old" policy (in the 
# primary schema). The merge algorithm proceeds in distinct phases:
#
# 1) Records which exist in the "old" policy but not in the "new" policy are deleted from the "old" policy.
# The comparison is performed by primary key, including the +policy_id+.
#
# 2) Records which are defined in some other policy in the primary schema, are removed from the "new" policy.
# This prevents the "new" policy from attempting to create or update records which are already owned by another policy.
# In the future, this might be reported as an error or warning.
#
# 3) Records which are identical in the "old" and "new" policy are deleted from the "new" policy, so they will not be
# considered for further processing.
#
# 4) Each record in the "old" policy which exists (by primary key comparison) in the "new" policy is updated with
# any non-primary fields which are defined in the "new" policy.
#
# 5) Step (3) is repeated, removing any exact duplicates between the "old" and "new" policies.
#
# 6) All records which remain in the "new" policy are inserted into the "old" policy.
#
# 7) The temporary schema is dropped, thus cleaning up any artifacts left over from the diff process. The schema search
# path is restored.
#
# 8) Perform any password updates.
#
# 9) Add any new public keys.
#
# All steps occur within a transaction, so that if any errors occur (e.g. a role or permission grant which references
# a non-existent role or resource), the entire operation is rolled back.
#
# Future: Note that it is also possible to skip step (1) (deletion of records from the "old" policy which are not defined in the 
# "new"). This "safe" mode can be operationally important, because the presence of cascading foreign key constraints in the schema
# means that many records can potentially be deleted as a consequence of deleting an important "root"-ish record. For
# example, deleting the "admin" role will most likely cascade to delete all records in the database.

module Loader
  class Orchestrate
    extend Forwardable
    include Schemata::Helper
    include Handlers::RestrictedTo
    include Handlers::Password
    include Handlers::PublicKey

    attr_reader :policy_version, :create_records, :delete_records, :new_roles, :schemata

    TABLES = %i[roles role_memberships resources permissions annotations]

    # Columns to compare across schemata to find exact duplicates.
    TABLE_EQUIVALENCE_COLUMNS = {
      roles: [ :role_id ],
      resources: [ :resource_id, :owner_id ],
      role_memberships: [ :role_id, :member_id, :admin_option, :ownership ],
      permissions: [ :resource_id, :privilege, :role_id ],
      annotations: [ :resource_id, :name, :value ]
    }

    def initialize policy_version
      @policy_version = policy_version
      @schemata = Schemata.new

      # Transform each statement into a Loader type
      @create_records = policy_version.create_records.map do |policy_object|
        Loader::Types.wrap(policy_object, self)
      end
      @delete_records = policy_version.delete_records.map do |policy_object|
        Loader::Types.wrap(policy_object, self)
      end
    end
    
    # Gets the id of the policy being loaded.
    def policy_id
      policy_version.policy.id
    end

    def setup_db_for_new_policy
      perform_deletion

      create_schema

      load_records
    end

    # TODO: consider renaming this method
    def delete_shadowed_and_duplicate_rows
      eliminate_shadowed

      eliminate_duplicates_exact
    end

    # TODO: consider renaming this method
    def store_policy_in_db
      eliminate_duplicates_pk

      insert_new

      drop_schema

      store_passwords

      store_public_keys

      store_restricted_to
    end

    def table_data schema = ""
      self.class.table_data(policy_version.policy.account, schema)
    end

    def print_debug
      puts("Temporary schema:")
      puts(table_data)
      puts
      puts("Master schema:")
      puts(table_data("#{primary_schema}__"))
    end

    class << self
      # Dump the table data to a pretty table-formatted string. Useful for debugging and inspection.
      def table_data account, schema = ""
        require 'table_print'
        io = StringIO.new
        tp.set(:io, io)
        tp.set(:max_width, 100)
        begin
          TABLES.each do |table|
            model = Sequel::Model("#{schema}#{table}".to_sym)
            account_column = TABLE_EQUIVALENCE_COLUMNS[table].include?(:resource_id) ? :resource_id : :role_id
            io.write("#{table}\n")
            sort_columns = TABLE_EQUIVALENCE_COLUMNS[table] + [ :policy_id ]
            tp(*([ model.where("account(#{account_column})".lit => account).order(sort_columns).all ] + TABLE_EQUIVALENCE_COLUMNS[table] + [ :policy_id ]))
            io.write("\n")
          end
        ensure
          tp.clear(:io)
        end
        io.rewind
        io.read
      end
    end

    # Delete rows in the existing policy which do not exist in the new policy.
    # Matching rows are selected by primary keys only, using a LEFT JOIN between the
    # existing policy and the new policy.
    def delete_removed
      TABLES.each do |table|
        columns = Array(model_for_table(table).primary_key) + [ :policy_id ]

        def comparisons table, columns, existing_alias, new_alias
          columns.map do |column|
            "#{existing_alias}#{table}.#{column} = #{new_alias}#{table}.#{column}"
          end.join(' AND ')
        end

        db[<<-DELETE, policy_version.resource_id].delete
          WITH deleted_records AS (
            SELECT existing_#{table}.*
            FROM #{qualify_table(table)} AS existing_#{table}
            LEFT OUTER JOIN #{table} AS new_#{table}
              ON #{comparisons(table, columns, 'existing_', 'new_')}
            WHERE existing_#{table}.policy_id = ? AND new_#{table}.#{columns[0]} IS NULL
          )
          DELETE FROM #{qualify_table(table)}
          USING deleted_records AS deleted_from_#{table}
          WHERE #{comparisons(table, columns, "#{primary_schema}.", 'deleted_from_')}
        DELETE
      end
    end

    # Delete rows from the new policy which are already present in another policy.
    def eliminate_shadowed
      TABLES.each do |table|
        pk_columns = Array(model_for_table(table).primary_key)
        comparisons = pk_columns.map do |column|
          "new_#{table}.#{column} = old_#{table}.#{column}"
        end.join(' AND ')
        db.execute(<<-DELETE)
          DELETE FROM #{table} new_#{table}
          USING #{qualify_table(table)} old_#{table}
          WHERE #{comparisons} AND
            ( old_#{table}.policy_id IS NULL OR old_#{table}.policy_id != new_#{table}.policy_id )
        DELETE
      end
    end

    # Delete rows from the new policy which are identical to existing rows.
    def eliminate_duplicates_exact
      TABLE_EQUIVALENCE_COLUMNS.each do |table, columns|
        eliminate_duplicates(table, columns + [ :policy_id ])
      end
    end

    # Delete rows from the new policy which have the same primary keys as existing rows.
    def eliminate_duplicates_pk
      TABLES.each do |table|
        eliminate_duplicates(table, Array(model_for_table(table).primary_key) + [ :policy_id ])
      end
    end

    # Eliminate duplicates from a table, using the specified comparison columns.
    def eliminate_duplicates table, columns
      comparisons = columns.map do |column|
        "new_#{table}.#{column} = old_#{table}.#{column}"
      end.join(' AND ')
      db.execute(<<-DELETE)
        DELETE FROM #{table} new_#{table}
        USING #{qualify_table(table)} old_#{table}
        WHERE #{comparisons}
      DELETE
    end

    def update_changed
      in_primary_schema do
        TABLES.each do |table|
          pk_columns = Array(Sequel::Model(table).primary_key)
          update_columns = TABLE_EQUIVALENCE_COLUMNS[table] - pk_columns
          next if update_columns.empty?

          update_statements = update_columns.map do |c|
            "#{c} = new_#{table}.#{c}"
          end.join(", ")

          join_columns = (pk_columns + [ :policy_id ]).map do |c|
            "#{table}.#{c} = new_#{table}.#{c}"
          end.join(" AND ")

          db.execute(<<-UPDATE)
            UPDATE #{table}
            SET #{update_statements}
            FROM #{schema_name}.#{table} new_#{table}
            WHERE #{join_columns}
          UPDATE
        end
      end
    end

    # Copy all remaining records in the new schema into the master schema.
    def insert_new
      @new_roles = ::Role.all

      in_primary_schema do
        disable_policy_log_trigger
        TABLES.each { |table| insert_table_records(table) }
        enable_policy_log_trigger
      end
    end

    def insert_table_records(table)
      columns = (TABLE_EQUIVALENCE_COLUMNS[table] + [ :policy_id ]).join(", ")          
      db.run("INSERT INTO #{table} ( #{columns} ) SELECT #{columns} FROM #{schema_name}.#{table}")
      
      # For large policies, the policy logging triggers occupy the majority
      # of the policy load time. To make this more efficient on the initial
      # load, we disable the triggers and update the policy log in bulk.
      insert_policy_log_records(table)
    end

    def disable_policy_log_trigger
      # To disable the triggers during the bulk load we use a local
      # configuration setting that the trigger function is aware of. 
      # When we set this variable to `true`, then the trigger will
      # observe the setting value and skip its own policy log.
      db.run('SET LOCAL conjur.skip_insert_policy_log_trigger = true')
    end

    def enable_policy_log_trigger
      db.run('SET LOCAL conjur.skip_insert_policy_log_trigger = false')
    end

    def insert_policy_log_records(table)
      primary_key_columns = Array(Sequel::Model(table).primary_key).map(&:to_s).pg_array
      db.run(<<-POLICY_LOG)
          INSERT INTO policy_log(
            policy_id, 
            version,
            operation, 
            kind, 
            subject)
          SELECT
          (policy_log_record(
            '#{table}',
            #{db.literal(primary_key_columns)},
            hstore(#{table}),
            #{db.literal(policy_id)},
            #{db.literal(policy_version[:version])},
            'INSERT'
            )).*
          FROM
          #{schema_name}.#{table}
      POLICY_LOG
    end

    # A random schema name.
    def schema_name
      @random ||= Random.new
      rnd = @random.bytes(8).unpack('h*').first
      @schema_name ||= "policy_loader_#{rnd}"
    end

    # Perform explicitly requested deletions
    def perform_deletion
      delete_records.map(&:delete!)
    end

    # Loads the records into the temporary schema (since the schema search path contains only the temporary schema).
    #
    #  
    def load_records
      raise "Policy version must be saved before loading" unless policy_version.resource_id

      create_records.map(&:create!)

      db[:role_memberships].where(admin_option: nil).update(admin_option: false)
      db[:role_memberships].where(ownership: nil).update(ownership: false)
      TABLES.each do |table|
        db[table].update(policy_id: policy_version.resource_id)
      end
    end

    def in_primary_schema &block
      restore_search_path

      yield

      # If a SQL exception occurs above, the transaction will be aborted and all database
      # calls will fail. So this statement is not performed in an `ensure` block.
      db.execute("SET search_path = #{schema_name}")
    end

    # Creates the new schema.
    #
    # Creates a set of tables in the new schema to mirror the tables in the primary schema.
    # The new tables are not created with constraints, aside from primary keys.
    def create_schema
      db.execute("CREATE SCHEMA #{schema_name}")
      db.search_path = schema_name

      TABLES.each do |table|
        db.execute("CREATE TABLE #{table} AS SELECT * FROM #{qualify_table(table)} WHERE 0 = 1")
      end

      db.execute(Functions.ownership_trigger_sql)

      db.execute(<<-SQL_STATEMENT)
      CREATE OR REPLACE FUNCTION account(id text) RETURNS text
      LANGUAGE sql IMMUTABLE
      AS $$
      SELECT CASE 
        WHEN split_part($1, ':', 1) = '' THEN NULL 
        ELSE split_part($1, ':', 1)
      END
      $$;
      SQL_STATEMENT

      db.execute("ALTER TABLE resources ADD PRIMARY KEY ( resource_id )")
      db.execute("ALTER TABLE roles ADD PRIMARY KEY ( role_id )")

      db.execute("ALTER TABLE role_memberships ALTER COLUMN admin_option SET DEFAULT 'f'")
    end

    # Drops the temporary schema and everything remaining in it. Also reset the schema search path.
    def drop_schema
      restore_search_path
      db.execute("DROP SCHEMA #{schema_name} CASCADE")
    end

    def db
      Sequel::Model.db
    end
  end
end
