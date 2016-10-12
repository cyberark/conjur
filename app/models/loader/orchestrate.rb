# Loads a policy into the database, by operating on a PolicyVersion which has already been created with the policy id, 
# policy text, the authenticated user, and the policy owner. The PolicyVersion also parses the policy
# and checks it for syntatic errors, before this code is invoked.
#
# The algorithm works by loading the policy into a new, temporary schema (schemas are lightweight namespaces
# in Postgres). Then this "new" policy (in the temporary schema) is merged into the "old" policy (in the 
# primary, public schema). The merge algorithm proceeds in distinct phases:
#
# 1) Records which exist in the "old" policy but not in the "new" policy are deleted from the "old" policy.
# The comparison is performed by primary key, including the +policy_id+.
#
# 2) Records which are defined in some other policy in the public schema, are removed from the "new" policy.
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
# path is reset to the 'public' schema.
#
# 8) Perform any password updates.
#
# 9) Add any new public keys.
#
# All steps occur within a transaction, so that if any errors occur (e.g. a role or permission grant which references
# a non-existant role or resource), the entire operation is rolled back.
#
# Future: Note that it is also possible to skip step (1) (deletion of records from the "old" policy which are not defined in the 
# "new"). This "safe" mode can be operationally important, because the presence of cascading foreign key constraints in the schema
# means that many records can potentially be deleted as a consequence of deleting an important "root"-ish record. For
# example, deleting the "admin" role will most likely cascade to delete all records in the database.

module Loader
  class Orchestrate
    extend Forwardable

    attr_reader :policy_version, :records, :policy_passwords, :policy_public_keys, :new_roles

    TABLES = %w(roles role_memberships resources permissions annotations)

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
      # Transform each statement into a Loader type
      @records = policy_version.records.map do |policy_object|
        Loader::Types.wrap self, policy_object
      end
      @policy_public_keys = []
      @policy_passwords = []
    end

    def load
      create_schema

      load_records

      delete_removed

      eliminate_shadowed

      eliminate_duplicates

      update_changed

      eliminate_duplicates

      insert_new

      drop_schema

      store_passwords

      store_public_keys
    end

    def table_data schema = ""
      self.class.table_data policy_version.policy.account, schema
    end

    def print_debug
      puts "Temporary schema:"
      puts table_data
      puts
      puts "Master schema:"
      puts table_data "public__"
    end

    class << self
      # Dump the table data to a pretty table-formatted string. Useful for debugging and inspection.
      def table_data account, schema = ""
        require 'table_print'
        io = StringIO.new
        tp.set :io, io
        tp.set :max_width, 100
        begin
          TABLES.each do |table|
            model = Sequel::Model("#{schema}#{table}".to_sym)
            account_column = TABLE_EQUIVALENCE_COLUMNS[table.to_sym].include?(:resource_id) ? :resource_id : :role_id
            io.write "#{table}\n"
            sort_columns = TABLE_EQUIVALENCE_COLUMNS[table.to_sym] + [ :policy_id ]
            tp *([ model.where("account(#{account_column}) = ?", account).order(sort_columns).all ] + TABLE_EQUIVALENCE_COLUMNS[table.to_sym] + [ :policy_id ])
            io.write "\n"
          end
        ensure
          tp.clear :io
        end
        io.rewind
        io.read
      end
    end

    protected

    # Update the public keys in the master schema, by comparing the public keys declared in the policy
    # with the existing public keys in the database.
    def store_public_keys
      policy_public_keys.each do |entry|
        id, public_key = entry
        resource = Resource[id]
        existing_secret = resource.secrets.last
        unless existing_secret && existing_secret.value == public_key
          ::Secret.create resource: resource, value: public_key
        end
      end
    end

    # Store all passwords which were encountered during the policy load. The passwords aren't declared in the
    # policy itself, they are obtained from the environment. This generally only happens when setting up the
    # +admin+ user in the bootstrap phase, but setting passwords for other users can be useful for dev/test.
    def store_passwords
      policy_passwords.each do |entry|
        id, password = entry
        $stderr.puts "Setting password for '#{id}'"
        role = ::Role[id]
        role.password = password
        role.save
      end
    end

    # When a public key is encountered in a policy, it is saved here. It can't be written directly into
    # the temporary schema, because that schema doesn't have a secrets table. The merge algorithm only operates
    # on the RBAC tables.
    def handle_password id, password
      policy_passwords << [ id, password ]
    end

    # When a public key is encountered in a policy, it is saved here. It can't be written directly into
    # the temporary schema, because that schema doesn't have a credentials table. The merge algorithm only operates
    # on the RBAC tables.
    def handle_public_key id, public_key
      policy_public_keys << [ id, public_key ]
    end

    # Delete rows in the existing policy which do not exist in the new policy.
    # Matching rows are selected by primary keys only, using a LEFT JOIN between the
    # existing policy and the new policy.
    def delete_removed
      TABLES.each do |table|
        columns = Array(Sequel::Model("public__#{table}".to_sym).primary_key) + [ :policy_id ]

        def comparisons table, columns, existing_alias, new_alias
          columns.map do |column|
            "#{existing_alias}#{table}.#{column} = #{new_alias}#{table}.#{column}"
          end.join(' AND ')
        end

        db[<<-DELETE, policy_version.resource_id].delete
          WITH deleted_records AS (
            SELECT existing_#{table}.*
            FROM public.#{table} AS existing_#{table}
            LEFT OUTER JOIN #{table} AS new_#{table}
              ON #{comparisons(table, columns, 'existing_', 'new_')}
            WHERE existing_#{table}.policy_id = ? AND new_#{table}.#{columns[0]} IS NULL
          )
          DELETE FROM public.#{table}
          USING deleted_records AS deleted_from_#{table}
          WHERE #{comparisons(table, columns, 'public.', 'deleted_from_')}
        DELETE
      end
    end

    # Delete rows from the new policy which are already present in another policy.
    def eliminate_shadowed
      TABLES.each do |table|
        pk_columns = Array(Sequel::Model("public__#{table}".to_sym).primary_key)
        comparisons = pk_columns.map do |column|
          "new_#{table}.#{column} = old_#{table}.#{column}"
        end.join(' AND ')
        db.execute <<-DELETE
          DELETE FROM #{table} new_#{table}
          USING public.#{table} old_#{table}
          WHERE #{comparisons} AND
            ( old_#{table}.policy_id IS NULL OR old_#{table}.policy_id != new_#{table}.policy_id )
        DELETE
      end
    end

    # Delete rows from the new policy which are identical to existing rows.
    def eliminate_duplicates
      TABLE_EQUIVALENCE_COLUMNS.each do |table, columns|
        comparisons = (columns + [ :policy_id ]).map do |column|
          "new_#{table}.#{column} = old_#{table}.#{column}"
        end.join(' AND ')
        db.execute <<-DELETE
          DELETE FROM #{table} new_#{table}
          USING public.#{table} old_#{table}
          WHERE #{comparisons}
        DELETE
      end
    end

    def update_changed
      in_primary_schema do
        TABLES.each do |table|
          pk_columns = Array(Sequel::Model(table.to_sym).primary_key)
          update_columns = TABLE_EQUIVALENCE_COLUMNS[table.to_sym] - pk_columns
          next if update_columns.empty?

          update_statements = update_columns.map do |c|
            "#{c} = new_#{table}.#{c}"
          end.join(", ")

          join_columns = (pk_columns + [ :policy_id ]).map do |c|
            "#{table}.#{c} = new_#{table}.#{c}"
          end.join(" AND ")

          db.execute <<-UPDATE
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
        TABLES.each do |table|
          columns = (TABLE_EQUIVALENCE_COLUMNS[table.to_sym] + [ :policy_id ]).join(", ")
          db.execute "INSERT INTO #{table} ( #{columns} ) SELECT #{columns} FROM #{schema_name}.#{table}"
        end
      end
    end

    # A securely random id.
    def schema_name
      @schema_name ||= "policy_loader_#{SecureRandom.hex}"
    end

    # Loads the records into the temporary schema (since the schema search path contains only the temporary schema).
    #
    #  
    def load_records
      raise "Policy version must be saved before loading" unless policy_version.resource_id

      records.map(&:create!)

      db[:role_memberships].where(admin_option: nil).update(admin_option: false)
      db[:role_memberships].where(ownership: nil).update(ownership: false)
      TABLES.each do |table|
        db[table.to_sym].update(policy_id: policy_version.resource_id)
      end
    end

    def in_primary_schema &block
      db.execute "SET search_path = public"
      begin
        yield
      ensure
        db.execute "SET search_path = #{schema_name}"
      end
    end

    # Creates the new schema.
    #
    # Creates a set of tables in the new schema to mirror the tables in the master (public) schema.
    # The new tables are not created with constraints, aside from primary keys.
    def create_schema
      db.execute "CREATE SCHEMA #{schema_name}"
      db.execute "SET search_path = #{schema_name}"

      TABLES.each do |table|
        db.execute "CREATE TABLE #{table} AS SELECT * FROM public.#{table} WHERE 0 = 1"
      end

      db.execute Functions.ownership_trigger_sql

      db.execute <<-SQL_STATEMENT
      CREATE OR REPLACE FUNCTION account(id text) RETURNS text
      LANGUAGE sql IMMUTABLE
      AS $$
      SELECT CASE 
         WHEN split_part($1, ':', 1) = '' THEN NULL 
        ELSE split_part($1, ':', 1)
      END
      $$;
      SQL_STATEMENT

      db.execute "ALTER TABLE resources ADD PRIMARY KEY ( resource_id )"
      db.execute "ALTER TABLE roles ADD PRIMARY KEY ( role_id )"

      db.execute "ALTER TABLE role_memberships ALTER COLUMN admin_option SET DEFAULT 'f'"
    end

    # Drops the temporary schema and everything remaining in it. Also reset the schema search path back to the
    # master (public) schema.
    def drop_schema
      db.execute "SET search_path = public"
      db.execute "DROP SCHEMA #{schema_name} CASCADE"
    end

    def db
      Sequel::Model.db
    end
  end
end