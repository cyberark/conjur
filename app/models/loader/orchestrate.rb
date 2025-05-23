# frozen_string_literal: true

require 'conjur/extension/repository'

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
  # As a legacy class, we know Orchestrate is too long and should be refactored
  # rubocop:disable Metrics/ClassLength
  #
  # We intentionally call @feature_flags.enabled? multiple times and don't
  # factor it out to make these checks easy to discover.
  # :reek:RepeatedConditional
  class Orchestrate
    # Constant for policy load extensions
    POLICY_LOAD_EXTENSION_KIND = :policy_load

    extend Forwardable
    include Schemata::Helper
    include Handlers::RestrictedTo
    include Handlers::Password
    include Handlers::PublicKey

    attr_reader :policy_parse,
                :policy_version,
                :create_records,
                :delete_records,
                :new_roles,
                :schemata,
                :visible_resource_hash_before,
                :visible_resource_hash_after,
                :diff,
                :credentials,
                :all_deleted_records,
                :all_created_records,
                :all_updated_records,
                :all_original_records

    TABLES = %i[roles role_memberships resources permissions annotations]

    # Columns to compare across schemata to find exact duplicates.
    TABLE_EQUIVALENCE_COLUMNS = {
      roles: [ :role_id ],
      resources: [ :resource_id, :owner_id ],
      role_memberships: [ :role_id, :member_id, :admin_option, :ownership ],
      permissions: [ :resource_id, :privilege, :role_id ],
      annotations: [ :resource_id, :name, :value ]
    }

    BASE_DIFF_RECORDS = {
      annotations: [],
      credentials: [],
      permissions: [],
      resources: [],
      role_memberships: [],
      roles: []
    }

    def initialize(
      policy_parse:,
      policy_version:,
      dryrun: false,
      data_object: DB::Repository::DataObjects::DiffElements,
      extension_repository: Conjur::Extension::Repository.new,
      feature_flags: Rails.application.config.feature_flags,
      policy_diff: CommandHandler::PolicyDiff.new,
      primitive_factory: DataObjects::PrimitiveFactory,
      resource: ::Resource,
      logger: Rails.logger
    )
      @all_created_records = BASE_DIFF_RECORDS.clone
      @all_deleted_records = BASE_DIFF_RECORDS.clone
      @all_original_records = BASE_DIFF_RECORDS.clone
      @all_updated_records = BASE_DIFF_RECORDS.clone
      @data_object = data_object
      @dryrun = dryrun
      @feature_flags = feature_flags
      @logger = logger
      @policy_diff = policy_diff
      @policy_parse = policy_parse
      @policy_version = policy_version
      @primitive_factory = primitive_factory
      @resource = resource
      @schemata = Schemata.new
      @visible_resource_hash_after = {}
      @visible_resource_hash_before = {}

      # Only attempt to load policy load extensions if the feature is enabled
      @extensions =
        if @feature_flags.enabled?(:policy_load_extensions)
          extension_repository.extension(kind: POLICY_LOAD_EXTENSION_KIND)
        end

      # Transform each statement into a Loader type
      @create_records = policy_parse.create_records.map do |policy_object|
        Loader::Types.wrap(policy_object, self)
      end
      @delete_records = policy_parse.delete_records.map do |policy_object|
        Loader::Types.wrap(policy_object, self)
      end
    end

    # Gets the id of the policy being loaded.
    def policy_id
      policy_version.policy.id
    end

    def create_policy(current_user:)
      return dryrun_create_policy(current_user) if @dryrun

      setup_db_for_new_policy
      delete_shadowed_and_duplicate_rows
      store_policy_in_db
      release_db_connection
    end

    def modify_policy(current_user:)
      return dryrun_modify_policy(current_user) if @dryrun

      setup_db_for_new_policy
      delete_shadowed_and_duplicate_rows
      upsert_policy_records
      clean_db
      store_auxiliary_data
      release_db_connection
    end

    def replace_policy(current_user:)
      return dryrun_replace_policy(current_user) if @dryrun

      setup_db_for_new_policy
      delete_removed
      delete_shadowed_and_duplicate_rows
      upsert_policy_records
      clean_db
      store_auxiliary_data
      release_db_connection
    end

    def actor_roles(roles)
      # A dryrun no longer yields these records due to the schema rollback
      # done in order to acquire the original resources.
      return [] if @dryrun

      roles.select do |role|
        %w[user host].member?(role.kind)
      end
    end

    def credential_roles(actor_roles)
      # A dryrun no longer yields these records due to the schema rollback
      # done in order to acquire the original resources. Without this change,
      # accessing this method would raise PG::ForeignKeyViolation
      # exception during a dryrun.
      return {} if @dryrun

      actor_roles.each_with_object({}) do |role, memo|
        credentials = Credentials[role: role] || Credentials.create(role: role)
        role_id = role.id
        memo[role_id] = { id: role_id, api_key: credentials.api_key }
      end
    end

    def report(policy_result)
      error = policy_result.error

      if error
        # The failure report identifies the error
        @logger.debug("#{error}\n")

        response = {
          error: error
        }

      else
        # The success report lists the roles
        response = {
          created_roles: policy_result.created_roles,
          version: @policy_version[:version]
        }

      end

      response
    end

    private

    # The order of primary keys is not significant in the query, however, to
    # aid in readability in the case of permissions, we prefer this order.
    def pks_preferred_order
      %i[resource_id role_id member_id]
    end

    def excluded_columns
      # The tables in the temp schema does not contain these columns, or
      # they are not pertinent to the diff operation.
      {
        credentials: %i[api_key created_at encrypted_hash expiration],
        resources: %i[created_at],
        roles: %i[created_at]
      }
    end

    def dryrun_create_policy(current_user)
      Sequel::Model.db.transaction(savepoint: true) do
        @visible_resource_hash_before = @resource.visible_to(current_user).each_with_object({}) do |obj, hash|
          hash[obj[:resource_id]] = true
        end || {}

        setup_db_for_new_policy
        delete_shadowed_and_duplicate_rows
        @all_created_records = fetch_created_rows
        @all_created_records[:credentials] = store_policy_in_db

        @visible_resource_hash_after = @resource.visible_to(current_user).each_with_object({}) do |obj, hash|
          hash[obj[:resource_id]] = true
        end || {}

        raise Sequel::Rollback
      end

      # It is imperative the rollback above is executed prior to this in order
      # for us to obtain these original records.
      @all_original_records = fetch_original_resources(@all_created_records, @all_deleted_records, @all_updated_records)

      @diff = create_diff(@all_created_records, @all_deleted_records, @all_original_records)

      release_db_connection
    end

    def dryrun_modify_policy(current_user)
      Sequel::Model.db.transaction(savepoint: true) do
        @visible_resource_hash_before = @resource.visible_to(current_user).each_with_object({}) do |obj, hash|
          hash[obj[:resource_id]] = true
        end

        setup_db_for_new_policy

        delete_shadowed_and_duplicate_rows

        @all_created_records = fetch_created_rows
        @all_updated_records = upsert_policy_records

        # This does not account for deleted role membership records when a role's
        # owner changes. Those are accounted for after this transaction completes
        # and we can compare the new owner membership records to the prior data.
        @all_deleted_records = dryrun_clean_db

        @all_created_records[:credentials] = store_auxiliary_data
        @visible_resource_hash_after = @resource.visible_to(current_user).each_with_object({}) do |obj, hash|
          hash[obj[:resource_id]] = true
        end

        raise Sequel::Rollback
      end

      # Include deleted role owner memberships in the set
      @all_deleted_records[:role_memberships].concat(
        deleted_role_owner_memberships(@all_created_records[:role_memberships])
      )

      # It is imperative the rollback above is executed prior to this in order
      # for us to obtain these original records.
      @all_original_records = fetch_original_resources(@all_created_records, @all_deleted_records, @all_updated_records)

      @diff = create_diff(@all_created_records, @all_deleted_records, @all_original_records)

      release_db_connection
    end

    def dryrun_replace_policy(current_user)
      Sequel::Model.db.transaction(savepoint: true) do
        @visible_resource_hash_before = @resource.visible_to(current_user).each_with_object({}) do |obj, hash|
          hash[obj[:resource_id]] = true
        end

        # Inserts into temp schema
        setup_db_for_new_policy
        # Fetches from temp schema + public schema
        @all_deleted_records = fetch_rows_to_be_deleted
        # Mutates primary schema
        delete_removed
        # Mutates primary schema
        delete_shadowed_and_duplicate_rows
        # Fetches from temp schema
        @all_created_records = fetch_created_rows
        # Mutates primary schema
        @all_updated_records = upsert_policy_records
        # Queries and Mutates primary schema

        dryrun_clean_db
        # Queries and Mutates primary schema
        @all_created_records[:credentials] = store_auxiliary_data

        @visible_resource_hash_after = @resource.visible_to(current_user).each_with_object({}) do |obj, hash|
          hash[obj[:resource_id]] = true
        end

        raise Sequel::Rollback
      end

      # It is imperative the rollback above is executed prior to this in order
      # for us to obtain these original records.
      @all_original_records = fetch_original_resources(@all_created_records, @all_deleted_records, @all_updated_records)

      @diff = create_diff(@all_created_records, @all_deleted_records, @all_original_records)

      release_db_connection
    end

    # Returns an array of resource_ids. These are the identifiers of resources
    # have been updated because they have been referenced by some attribute in
    # @all_created_records @all_updated_records and @all_deleted_records.
    def calculate_updated_resources(created_records, deleted_records, updated_records)
      table_map = {
        annotations: %i[resource_id],
        resources: %i[resource_id],
        roles: %i[role_id],
        credentials: %i[role_id],
        permissions: %i[resource_id role_id],
        role_memberships: %i[role_id member_id]
      }

      identifiers = table_map.each_with_object(Set.new) do |(key, fields), set|
        created_ids = get_identifiers(created_records, key, fields)
        updated_ids = get_identifiers(deleted_records, key, fields)
        deleted_ids = get_identifiers(updated_records, key, fields)

        set.merge(created_ids)
        set.merge(updated_ids)
        set.merge(deleted_ids)
      end

      identifiers.to_a
    end

    def get_identifiers(records, key, fields)
      records[key]&.flat_map { |record| fields.map { |field| record[field] } } || []
    end

    # This method returns role membership records that were deleted because
    # they were replaced by a new role membership for a new owner.
    def deleted_role_owner_memberships(created_role_memberships)
      # Check to see if there were any role membership owner records created
      role_owner_memberships_to_check = \
        created_role_memberships
          .select { |rm| rm[:ownership] }
          .map { |rm| rm[:role_id] }


      # If there were no created records, then there were no replaced (deleted)
      # records.
      return [] unless role_owner_memberships_to_check.any?

      fully_qualified_role_owner_table = "#{role_owner_schema}.#{role_owner_table_name}"

      create_role_owner_schema(role_owner_memberships_to_check)

      # Query for prior owner membership records for the roles that had owner
      # memberships created. If there are any, these were deleted when they
      # were replaced and should be returned.
      model = model_for_table('role_memberships')
      pks = reorder_array(array: Array(model.primary_key), preferred_order: pks_preferred_order)
      cols = model.columns - (excluded_columns['role_memberships'] || [])
      sql = <<-SQL
        SELECT #{cols.map { |col| "role_memberships.#{col}" }.join(', ')}
        FROM role_memberships
        JOIN #{fully_qualified_role_owner_table} ON #{fully_qualified_role_owner_table}.role_id = role_memberships.role_id
        AND ownership is true
        ORDER BY #{pks.map { |pk| "role_memberships.#{pk}" }.join(', ')}
      SQL

      db[sql].all
    ensure
      cleanup_role_owner_schema
    end

    def fetch_created_rows
      result = BASE_DIFF_RECORDS.clone

      # Fetch newly created rows (after they've been loaded, dupes deleted, and
      # before being cleaned up)
      TABLES.each do |table|
        model = model_for_table(table)
        cols = model.columns - (excluded_columns[table.to_sym] || [])
        pks = Array(model.primary_key)
        pks = reorder_array(array: pks, preferred_order: pks_preferred_order)
        result[table.to_sym] = db.fetch("SELECT #{cols.map(&:to_s).join(', ')} from #{table} ORDER BY #{pks.map(&:to_s).join(', ')}").all
      end
      result
    end

    def setup_db_for_new_policy
      # We use the db setup to signal the start of a policy load
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(:before_load_policy, policy_version: @policy_version)
      end

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

      perform_deletion

      store_passwords

      store_public_keys

      # Returns the created restricted_to records
      store_restricted_to(false)
    end

    def stash_new_roles
      pk_columns = Array(Sequel::Model(:roles).primary_key)
      pk_columns_with_policy_id = pk_columns + [ :policy_id ]
      join_columns = pk_columns_with_policy_id.map do |c|
        "public_roles.#{c} = new_roles.#{c}"
      end.join(" AND ")

      # getting newly added roles
      new_roles_sql = <<-SQL
          SELECT *
          FROM #{schema_name}.roles new_roles
          WHERE NOT EXISTS (
            SELECT 1
            FROM #{primary_schema}.roles public_roles
            WHERE ( #{join_columns} )
          );
      SQL

      new_roles_dataset = db.fetch(new_roles_sql)
      @new_roles = new_roles_dataset.map{ |ds| Role.new(ds) }
    end

    def upsert_policy_records
      result = BASE_DIFF_RECORDS.clone

      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :before_insert,
          policy_version: @policy_version,
          schema_name: schema_name
        )
        @extensions.call(
          :before_update,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end

      # We need to get newly created roles and save them in the class field before further changes.
      # This is the last place we can do it.
      stash_new_roles
      in_primary_schema do
        TABLES.each do |table|
          model = model_for_table(table)

          # Preparation for moving newly added entries from temporary
          # schema to the public schema
          pk_columns = Array(model.primary_key)
          pk_columns_with_policy_id = pk_columns + [ :policy_id ]

          # Diff data that we're taking out of this operation
          select_cols = model.columns - (excluded_columns[table] || [])

          join_columns = pk_columns_with_policy_id.map do |c|
            "#{table}.#{c} = new_#{table}.#{c}"
          end.join(" AND ")
          insert_columns = (TABLE_EQUIVALENCE_COLUMNS[table] + [ :policy_id ]).join(", ")

          # Preparing columns to be used during update.
          # Value for policy_id will not be changed during update
          # but for readability (one generic flow) and consistency with the rest of the code
          # we are using list of columns with policy_id
          update_columns = TABLE_EQUIVALENCE_COLUMNS[table] - pk_columns + [:policy_id]
          update_statements = update_columns.map do |c|
            "#{c} = new_#{table}.#{c}"
          end.join(", ")
          updated_records = db[<<-UPSERT].all
          WITH inserted AS (
            INSERT INTO #{table} (#{insert_columns})
            SELECT #{insert_columns}
            FROM #{schema_name}.#{table} new_#{table}
            ON CONFLICT (#{pk_columns.join(', ')}) DO NOTHING
            RETURNING #{pk_columns.join(', ')}
          ),
          updated AS (
            UPDATE #{table}
            SET #{update_statements}
            FROM #{schema_name}.#{table} new_#{table}
            WHERE NOT EXISTS (
              SELECT 1
              FROM inserted i
              WHERE #{pk_columns.map { |c| "i.#{c} = #{table}.#{c}" }.join(' AND ')}
            ) AND #{join_columns}
            RETURNING #{select_cols.map { |col| "#{table}.#{col}" }.join(', ')}
          )
          SELECT * FROM updated
          UPSERT

          result[table.to_sym] = updated_records
        end
      end

      # We want to use the if statement here to wrap the feature flag check
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :after_insert,
          policy_version: @policy_version,
          schema_name: schema_name
        )
        @extensions.call(
          :after_update,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end

      result
    end

    def clean_db
      drop_schema

      perform_deletion
    end

    def dryrun_clean_db
      drop_schema

      # Obtain the records we explicitly asked to destroy
      results = dryrun_perform_deletion

      # Actually destroy them
      perform_deletion

      results
    end

    def store_auxiliary_data
      store_passwords

      store_public_keys

      # Returns the created restricted_to records
      store_restricted_to(true)
    end

    def diff_schema_name
      @random ||= Random.new
      rnd = @random.bytes(8).unpack('h*').first
      @diff_schema_name ||= "policy_loader_before_#{rnd}"
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
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :before_delete,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end

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

      # We want to use the if statement here to wrap the feature flag check
      # rubocop:disable Style/GuardClause
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :after_delete,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end
      # rubocop:enable Style/GuardClause
    end

    # This will return the rows that would be deleted by delete_removed.
    def fetch_rows_to_be_deleted
      result = BASE_DIFF_RECORDS.clone
      temp = {}

      # Determine which roles/resources are pending deletion. This is taken
      # from delete_removed.
      TABLES.each do |table|
        model = model_for_table(table)
        cols = model.columns - (excluded_columns[table] || [])
        comparison_cols = Array(model.primary_key) + [ :policy_id ]

        def comparisons table, comparison_cols, existing_alias, new_alias
          comparison_cols.map do |column|
            "#{existing_alias}#{table}.#{column} = #{new_alias}#{table}.#{column}"
          end.join(' AND ')
        end

        def join_comparisons table, comparison_cols, existing_alias, new_alias
          comparison_cols.map do |column|
            "#{existing_alias}#{column} = #{new_alias}#{table}.#{column}"
          end.join(' AND ')
        end

        result[table.to_sym] = db[<<-DELETE, policy_version.resource_id].all
        WITH deleted_records AS (
          SELECT existing_#{table}.*
          FROM #{qualify_table(table)} AS existing_#{table}
          LEFT OUTER JOIN #{table} AS new_#{table}
            ON #{comparisons(table, comparison_cols, 'existing_', 'new_')}
          WHERE existing_#{table}.policy_id = ? AND new_#{table}.#{comparison_cols[0]} IS NULL
        )
        SELECT #{cols.map { |col| "deleted_from_#{table}.#{col}" }.join(', ')} FROM deleted_records AS deleted_from_#{table}
          JOIN #{qualify_table(table)} AS existing_#{table}
          ON #{join_comparisons(table, comparison_cols, "existing_#{table}.", 'deleted_from_')}
        DELETE
      end

      # Collect the roles/resources that have been deleted and determine which
      # attributes would be deleted as well.
      identifiers = Set.new(result[:resources].map { |obj| obj[:resource_id] }) | Set.new(result[:roles].map { |obj| obj[:role_id] })
      in_primary_schema do
        temp = fetch_dependent_attributes(identifiers.to_a)
      end

      # The attributes fetched do not contain the full picture of
      # roles/resources to be deleted on their own, so we merge the two results
      # together.
      result[:annotations] = (Set.new(temp[:annotations]) | Set.new(result[:annotations])).to_a
      result[:credentials] = (Set.new(temp[:credentials]) | Set.new(result[:credentials])).to_a
      result[:permissions] = (Set.new(temp[:permissions]) | Set.new(result[:permissions])).to_a
      result[:resources] = (Set.new(temp[:resources]) | Set.new(result[:resources])).to_a
      result[:role_memberships] = (Set.new(temp[:role_memberships]) | Set.new(result[:role_memberships])).to_a
      result[:credentials] = (Set.new(temp[:credentials]) | Set.new(result[:credentials])).to_a
      result[:roles] = (Set.new(temp[:roles]) | Set.new(result[:roles])).to_a

      result
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

    # We intentionally call @feature_flags.enabled? multiple times and don't
    # factor it out to make these checks easy to discover.
    # :reek:DuplicateMethodCall
    def update_changed
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :before_update,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end

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

      # We want to use the if statement here to wrap the feature flag check
      # rubocop:disable Style/GuardClause
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :after_update,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end
      # rubocop:enable Style/GuardClause
    end

    # Copy all remaining records in the new schema into the master schema.
    #
    # We intentionally call @feature_flags.enabled? multiple times and don't
    # factor it out to make these checks easy to discover.
    # :reek:DuplicateMethodCall
    def insert_new
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :before_insert,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end

      @new_roles = ::Role.all

      in_primary_schema do
        TABLES.each do |table|
          @all_created_records[table.to_sym] = insert_table_records(table)
        end
      end

      # We want to use the if statement here to wrap the feature flag check
      # rubocop:disable Style/GuardClause
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :after_insert,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end
      # rubocop:enable Style/GuardClause
    end

    def insert_table_records(table)
      model = model_for_table(table)
      pks = Array(model.primary_key)
      pks = reorder_array(array: pks, preferred_order: pks_preferred_order)
      columns = (TABLE_EQUIVALENCE_COLUMNS[table] + [ :policy_id ]).join(", ")

      db[<<-SQL].all
        INSERT INTO #{table} ( #{columns} )
        SELECT #{columns} FROM #{schema_name}.#{table}
        ORDER BY #{pks.map(&:to_s).join(', ')}
        RETURNING *
      SQL

    end

    # A random schema name.
    def schema_name
      @random ||= Random.new
      rnd = @random.bytes(8).unpack('h*').first
      @schema_name ||= "policy_loader_#{rnd}"
    end

    # Perform explicitly requested deletions
    #
    # We intentionally call @feature_flags.enabled? multiple times and don't
    # factor it out to make these checks easy to discover.
    # :reek:DuplicateMethodCall
    def perform_deletion
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :before_delete,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end

      delete_records.map(&:delete!)

      # We want to use the if statement here to wrap the feature flag check
      # rubocop:disable Style/GuardClause
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :after_delete,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end
      # rubocop:enable Style/GuardClause
    end

    # Perform explicitly requested deletions during a dryrun
    #
    # The purpose of this method is to determine which records are explicitly
    # destroyed. We don't want to actually destroy them, since immediately
    # after this call we need to see what attributes are associated with them,
    # and we can't do that if they're deleted...
    #
    # :reek:DuplicateMethodCall
    #
    def dryrun_perform_deletion
      resource_ids = []
      deleted_records = {}
      result = BASE_DIFF_RECORDS.clone

      should_destroy_record = !@dryrun
      records = delete_records.flat_map { |record| record.delete!(destroy: should_destroy_record) }

      # Convert the record to a hash
      deleted_records = records.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |obj, hash|
        table_name = obj.class.table_name.to_sym
        # Exclude any columns that we don't care about
        filtered_obj = obj.values.reject { |key, _| excluded_columns[table_name.to_sym]&.include?(key) }
        hash[table_name] << filtered_obj
      end

      # Get all resource_ids that are deleted...
      if deleted_records[:resources]
        resource_ids = deleted_records[:resources].map { |resource| resource[:resource_id] }
      end

      # ... then get all attributes associated with it. This is why skipping
      # deletion is important!
      implicitly_deleted_rows_by_table = fetch_dependent_attributes(resource_ids)

      # ... and combine them with the produced hash
      result.keys.each_with_object(result) do |table, hash|
        key = table.to_sym
        next unless deleted_records.key?(key) || implicitly_deleted_rows_by_table.key?(key)

        hash[key] = Array(deleted_records[key]) + Array(implicitly_deleted_rows_by_table[key])
      end
    end

    # Returns the rows related to the roles/resources from the original policy
    # that will be updated by the input policy.
    def fetch_original_resources(created_records, deleted_records, updated_records)
      identifiers = calculate_updated_resources(created_records, deleted_records, updated_records)
      fetch_dependent_attributes(identifiers, include_roles_and_resources: true)

    end

    def related_identifiers_schema
      @random ||= Random.new
      rnd = @random.bytes(8).unpack('h*').first
      @related_identifiers_schema ||= "policy_loader_identifiers_#{rnd}"
    end

    def related_identifiers_table_name
      "related_identifiers"
    end

    def role_owner_schema
      @random ||= Random.new
      rnd = @random.bytes(8).unpack('h*').first
      @role_owner_schema ||= "policy_loader_role_owners_#{rnd}"
    end

    def role_owner_table_name
      "role_owners"
    end

    # Create a temporary schema used to contain resource_ids. These are used
    # for a more performant JOIN, where the alternative is a slower WHERE IN
    # clause. This is used to derive attribute records related to a
    # role/resource via Foreign Key constraints.
    def create_related_identifiers_schema(identifiers)
      original_search_path = db.search_path

      db.execute("CREATE SCHEMA #{related_identifiers_schema}")

      db.search_path = related_identifiers_schema

      db.execute("CREATE TABLE #{related_identifiers_schema}.#{related_identifiers_table_name} (resource_id TEXT PRIMARY KEY)")

      # We use multi_insert to insert in a batch as opposed to one at a time.
      fully_qualified_table_name = Sequel.qualify(related_identifiers_schema, related_identifiers_table_name)
      data = identifiers.uniq.map { |id| { resource_id: id } }
      data.each_slice(1000) do |batch|
        db[fully_qualified_table_name].multi_insert(batch)
      end

      db.search_path = original_search_path
    end

    def cleanup_related_identifiers_schema
      db.execute("DROP SCHEMA IF EXISTS #{related_identifiers_schema} CASCADE")
    rescue => err
      @logger.error(
        "Failed to cleanup temporary dry-run schema " \
        "'#{related_identifiers_schema}': #{err}"
      )
    end

    # Create a temporary schema used to contain resource_ids for created role
    # owner members. These are used for a more performant JOIN, where the
    # alternative is a slower WHERE IN clause.
    def create_role_owner_schema(identifiers)
      original_search_path = db.search_path

      db.execute("CREATE SCHEMA #{role_owner_schema}")

      db.search_path = role_owner_schema

      db.execute("CREATE TABLE #{role_owner_schema}.#{role_owner_table_name} (role_id TEXT PRIMARY KEY)")

      # We use multi_insert to insert in a batch as opposed to one at a time.
      fully_qualified_table_name = Sequel.qualify(role_owner_schema, role_owner_table_name)
      data = identifiers.uniq.map { |id| { role_id: id } }
      data.each_slice(1000) do |batch|
        db[fully_qualified_table_name].multi_insert(batch)
      end

      db.search_path = original_search_path
    end

    def cleanup_role_owner_schema
      db.execute("DROP SCHEMA IF EXISTS #{role_owner_schema} CASCADE")
    rescue => err
      @logger.error(
        "Failed to cleanup temporary dry-run schema " \
        "'#{role_owner_schema}': #{err}"
      )
    end

    # Returns a list of foreign keys by table.
    def fetch_foreign_keys_by_table(tables)
      tables.each_with_object({}) do |t, hash|
        model = model_for_table(t)
        fks = db.foreign_key_list(model.table_name)
        hash[t] = fks
      end
    end

    # Returns the list of attribute tables. These are derived from TABLES,
    # but also includes the credentials table.
    def attribute_tables(tables)
      tables.reject { |table| [:roles, :resources].include?(table) } + [:credentials]
    end

    # Given a list of foreign keys, returns an array containing each dependent
    # column.
    def extract_conditions_from_dependent_tables(constraints)
      constraints.each_with_object([]) do |constraint, array|
        next unless constraint[:on_delete] == :cascade

        constraint_key = constraint[:columns].first
        array << constraint_key
      end
    end

    # Returns all rows from TABLES that would be affected by the deletion of a
    # resource (e.g. annotations, role_memberships, permissions). This operates
    # on foreign key constraints.
    #
    # This method is used in the following contexts:
    # - Deriving related attributes that will be implicitly deleted by some
    #   policy operation
    # - Fetching original resources
    #
    # IMPORTANT: we only want to include roles and resources in the case of:
    # - Fetching original resources
    #
    # This logic is nested here to take advantage of the SQL JOINs
    # on the related identifiers table.
    def fetch_dependent_attributes(identifiers, include_roles_and_resources: false)
      result =
        {
          annotations: [],
          credentials: [],
          permissions: [],
          resources: [],
          role_memberships: [],
          roles: []
        }
      fully_qualified_related_identifiers_table = "#{related_identifiers_schema}.#{related_identifiers_table_name}"

      create_related_identifiers_schema(identifiers)

      filtered_tables = attribute_tables(TABLES)
      fks_by_table = fetch_foreign_keys_by_table(filtered_tables)

      fks_by_table.each do |table, constraints|
        model = model_for_table(table)
        result[table.to_sym] ||= []

        conditions = extract_conditions_from_dependent_tables(constraints)
        next if conditions.empty?

        pks = reorder_array(array: Array(model.primary_key), preferred_order: pks_preferred_order)
        cols = model.columns - (excluded_columns[table] || [])
        join_conditions = conditions.map { |constraint_key| "#{related_identifiers_table_name}.resource_id = #{table}.#{constraint_key}" }.join(' OR ')

        sql = <<-SQL
          SELECT #{cols.map { |col| "#{table}.#{col}" }.join(', ')}
          FROM #{table}
          JOIN #{fully_qualified_related_identifiers_table} ON #{join_conditions}
          ORDER BY #{pks.map { |pk| "#{table}.#{pk}" }.join(', ')}
        SQL
        rows = db[sql].all
        result[table.to_sym].concat(rows)
      end

      if include_roles_and_resources
        result[:resources] = fetch_primary_rows(:resources)
        result[:roles] = fetch_primary_rows(:roles)
      end

      result
    ensure
      cleanup_related_identifiers_schema
    end

    # Returns a list of rows from the given tables whose primary keys are in
    # the related identifiers table.
    def fetch_primary_rows(table)
      fully_qualified_related_identifiers_table = "#{related_identifiers_schema}.#{related_identifiers_table_name}"

      model = model_for_table(table)
      pks = reorder_array(array: Array(model.primary_key), preferred_order: pks_preferred_order)
      cols = model.columns - (excluded_columns[table] || [])

      sql = <<-SQL
        SELECT #{cols.map { |col| "#{table}.#{col}" }.join(', ')}
        FROM #{table}
        JOIN #{fully_qualified_related_identifiers_table} ON #{fully_qualified_related_identifiers_table}.resource_id = #{table}.#{model.primary_key}
        ORDER BY #{pks.map { |pk| "#{table}.#{pk}" }.join(', ')}
      SQL
      db[sql].all

    end

    # Loads the records into the temporary schema (since the schema search path
    # contains only the temporary schema).
    def load_records
      raise "Policy version must be saved before loading" unless policy_version.resource_id

      create_records.map(&:create!)

      db[:role_memberships].where(admin_option: nil).update(admin_option: false)
      db[:role_memberships].where(ownership: nil).update(ownership: false)
      TABLES.each do |table|
        db[table].update(policy_id: policy_version.resource_id)
      end
    end

    # This executes the provided block within the context of the public schema.
    # IMPORTANT: this will revert the schema_path to the temp schema afterwards!
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

      db.execute(Functions.ownership_trigger_sql_orchestrate)

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

      # We want to use the if statement here to wrap the feature flag check
      # rubocop:disable Style/GuardClause
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(
          :after_create_schema,
          policy_version: @policy_version,
          schema_name: schema_name
        )
      end
      # rubocop:enable Style/GuardClause
    end

    # Drops the temporary schema and everything remaining in it. Also reset the schema search path.
    def drop_schema
      restore_search_path
      db.execute("DROP SCHEMA #{schema_name} CASCADE")

      # We want to use the if statement here to wrap the feature flag check
      # rubocop:disable Style/GuardClause
      if @feature_flags.enabled?(:policy_load_extensions)
        # We use dropping the temp schema to represent the end of a policy load
        @extensions.call(:after_load_policy, policy_version: policy_version)
      end
      # rubocop:enable Style/GuardClause
    end

    def db
      Sequel::Model.db
    end

    # Returns an array of unique table rows filtered by the primary key(s) of
    # the given table.
    def filter_unique_records(records, table_name)
      model = model_for_table(table_name)
      pks = Array(model.primary_key)
      records.uniq { |hash| pks.map { |pk| hash[pk] } }
    end

    # Uses the records to create the diff that is ready to be consumed by
    # the dryrun report method. Due to the nature of the diff being assembed
    # via multiple separate queries, it is possible that any of parameters
    # will contain duplicate records. Therefore, they must be made distinct.
    def create_diff(created_records, deleted_records, original_records)
      created = @data_object.new(
        diff_type: 'created',
        annotations: filter_unique_records(created_records[:annotations], :annotations),
        permissions: filter_unique_records(created_records[:permissions], :permissions),
        resources: filter_unique_records(created_records[:resources], :resources),
        role_memberships: filter_unique_records(created_records[:role_memberships], :role_memberships),
        roles: filter_unique_records(created_records[:roles], :roles),
        credentials: filter_unique_records(created_records[:credentials], :credentials)
      )

      deleted = @data_object.new(
        diff_type: 'deleted',
        annotations: filter_unique_records(deleted_records[:annotations], :annotations),
        permissions: filter_unique_records(deleted_records[:permissions], :permissions),
        resources: filter_unique_records(deleted_records[:resources], :resources),
        role_memberships: filter_unique_records(deleted_records[:role_memberships], :role_memberships),
        roles: filter_unique_records(deleted_records[:roles], :roles),
        credentials: filter_unique_records(deleted_records[:credentials], :credentials)
      )

      original = @data_object.new(
        diff_type: 'original',
        annotations: filter_unique_records(original_records[:annotations], :annotations),
        permissions: filter_unique_records(original_records[:permissions], :permissions),
        resources: filter_unique_records(original_records[:resources], :resources),
        role_memberships: filter_unique_records(original_records[:role_memberships], :role_memberships),
        roles: filter_unique_records(original_records[:roles], :roles),
        credentials: filter_unique_records(original_records[:credentials], :credentials)
      )
      @policy_diff.call(created: created, deleted: deleted, original: original).result
    end

    # PostgreSQL has many types of caches, one of which is the "catalog cache".
    # When a connection is established to the database, this cache is initialized alongside it, and persists for the duration of the connection.
    # This cache contains references to Database Objects, such as indexes, etc. (not data records themselves).
    # This cache is not cleaned up by the system automatically. However, if the connection is disconnected, the cache is dumped.
    # further reading: Postgres community email thread: https://www.postgresql.org/message-id/flat/20161219.201505.11562604.horiguchi.kyotaro@lab.ntt.co.jp.
    # The default connection pool does not support closing connections.We must be able to close connections on demand
    # to clear the connection cache after policy loads [cyberark/conjur#2584](https://github.com/cyberark/conjur/pull/2584)
    # The ShardedThreadedConnectionPool does support closing connections on-demand
    # [docs](https://www.rubydoc.info/github/jeremyevans/sequel/Sequel/ShardedThreadedConnectionPool)
    def release_db_connection
      Sequel::Model.db.disconnect
    end

    # Returns a array of values in the preferred order (if they exist).
    # Missing columns are never included in the result.
    def reorder_array(array:, preferred_order:)
      # Extract the preferred elements that exist in the original array:
      preferred_elements = preferred_order & array

      # Extract the remaining elements that are not in the preferred order
      remaining_elements = array - preferred_elements

      # Combine the preferred elements and the remaining elements
      preferred_elements + remaining_elements
    end
  end
  # rubocop:enable Metrics/ClassLength
end
