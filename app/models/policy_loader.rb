# Loads a policy into the database.
#
# PolicyLoader operates on a PolicyVersion which has already been created with the policy id, 
# policy text, the authenticated user, and the policy owner. The PolicyVersion also parses the policy
# and checks it for syntatic errors, before PolicyLoader is invoked.
#
# PolicyLoader works by loading the policy into a new, temporary schema (schemas are lightweight namespaces
# in Postgres). The this "new" policy (in the temporary schema) is diff-ed against the "old" policy (in the 
# primary, public schema). The diff proceeds in distinct phases:
#
# 1) Records which exist in the "old" policy but not in the "new" policy are deleted from the "old" policy.
# The comparison is performed by primary key, including the +policy_id+.
#
# 2) Records which are defined in some other policy in the public schema, are removed from the "new" policy.
# This prevents the "new" policy from attempting to create or update records which are already owned by another policy.
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
# Finally, the temporary schema is dropped, thus cleaning up any artifacts left over from the diff process.
#
# All steps occur within a transaction, so that if any errors occur (e.g. a role or permission grant which references
# a non-existant role or resource), the entire operation is rolled back.
#
# Note that it is also possible to skip step (1) (deletion of records from the "old" policy which are not defined in the 
# "new"). This "safe" mode can be operationally important, because the presence of cascading foreign key constraints in the schema
# means that many records can potentially be deleted as a consequence of deleting an important "root"-ish record. For
# example, deleting the "admin" role will most likely cascade to delete all records in the database.

class PolicyLoader
  extend Forwardable

  def_delegators :@policy_version, :resource_id, :policy_admin

  attr_reader :policy_version

  TABLES = %w(roles resources role_memberships permissions annotations)

  # Columns to compare across schemata to find exact duplicates.
  TABLE_EQUIVALENCE_COLUMNS = {
    roles: [ :role_id ],
    resources: [ :resource_id, :owner_id ],
    role_memberships: [ :role_id, :member_id, :admin_option ],
    permissions: [ :resource_id, :privilege, :role_id ],
    annotations: [ :resource_id, :name, :value ]
  }

  def initialize policy_version
    @policy_version = policy_version
  end

  def load
    db.transaction do
      create_schema

      load_records

      delete_removed

      eliminate_shadowed

      eliminate_duplicates

      update_changed

      eliminate_duplicates

      insert_new

      drop_schema
    end
  end

  def table_data schema = ""
    self.class table_data schema
  end

  class << self
    def table_data schema = ""
      require 'table_print'
      io = StringIO.new
      tp.set :io, io
      tp.set :max_width, 100
      begin
        TABLES.each do |table|
          model = Sequel::Model("#{schema}#{table}".to_sym)
          io.write "#{table}\n"
          tp *([ model.all ] + TABLE_EQUIVALENCE_COLUMNS[table.to_sym] + [ :policy_id ])
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

      db[<<-DELETE, resource_id].delete
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
    TABLES.each do |table|
      pk_columns = Array(Sequel::Model("public__#{table}".to_sym).primary_key)
      update_columns = TABLE_EQUIVALENCE_COLUMNS[table.to_sym] - pk_columns
      next if update_columns.empty?

      update_statements = update_columns.map do |c|
        "#{c} = new_#{table}.#{c}"
      end.join(", ")

      join_columns = (pk_columns + [ :policy_id ]).map do |c|
        "public.#{table}.#{c} = new_#{table}.#{c}"
      end.join(" AND ")

      db.execute <<-UPDATE
        UPDATE public.#{table}
        SET #{update_statements}
        FROM #{table} new_#{table}
        WHERE #{join_columns}
      UPDATE
    end
  end

  def insert_new
    TABLES.each do |table|
      columns = (TABLE_EQUIVALENCE_COLUMNS[table.to_sym] + [ :policy_id ]).join(", ")
      db.execute "INSERT INTO public.#{table} ( #{columns} ) SELECT #{columns} FROM #{table}"
    end
  end

  def schema_name
    @schema_name ||= "policy_loader_#{SecureRandom.hex}"
  end

  def load_records
    raise "Policy version must be saved before loading" unless resource_id

    policy_owner = ::Role.create(role_id: policy_admin.id)

    policy_version.records.map(&:create!)

    policy_owner.destroy

    TABLES.each do |table|
      db[table.to_sym].update(policy_id: resource_id)
    end
  end

  def create_schema
    db.execute "CREATE SCHEMA #{schema_name}"
    db.execute "SET LOCAL search_path = #{schema_name}"
    TABLES.each do |table|
      db.execute "CREATE TABLE #{table} AS SELECT * FROM public.#{table} WHERE 0 = 1"
    end

    db.execute "ALTER TABLE resources ADD PRIMARY KEY ( resource_id )"
    db.execute "ALTER TABLE roles ADD PRIMARY KEY ( role_id )"

    db.execute "ALTER TABLE role_memberships ALTER COLUMN admin_option SET DEFAULT 'f'"
  end

  def drop_schema
    db.execute "DROP SCHEMA #{schema_name} CASCADE"
  end

  def db
    Sequel::Model.db
  end
end