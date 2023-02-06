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
require 'securerandom'
require 'aws-sdk-sqs'
require 'aws-sdk-sts'


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

    attr_reader :policy_version, :create_records, :delete_records, :new_roles, :schemata
    #changed_records = {}

    TABLES = %i[roles role_memberships resources permissions annotations]

    # Columns to compare across schemata to find exact duplicates.
    TABLE_EQUIVALENCE_COLUMNS = {
      roles: [ :role_id ],
      resources: [ :resource_id, :owner_id ],
      role_memberships: [ :role_id, :member_id, :admin_option, :ownership ],
      permissions: [ :resource_id, :privilege, :role_id ],
      annotations: [ :resource_id, :name, :value ]
    }

    def initialize(
      policy_version,
      extension_repository: Conjur::Extension::Repository.new,
      feature_flags: Rails.application.config.feature_flags
    )
      @policy_version = policy_version
      @schemata = Schemata.new
      @feature_flags = feature_flags
      Rails.logger.info("+++++++++++ Orchestrate::initialize")
      transaction_id = SecureRandom.uuid
      Rails.logger.info("+++++++++++ Orchestrate::initialize 1 transaction id = #{transaction_id}")
      # Only attempt to load policy load extensions if the feature is enabled
      @extensions =
        if @feature_flags.enabled?(:policy_load_extensions)
          extension_repository.extension(kind: POLICY_LOAD_EXTENSION_KIND)
        end
      #changed_records[transaction_id] = "["
      Rails.logger.info("+++++++++++ Orchestrate::initialize 2 transaction id = #{transaction_id}")
      # Transform each statement into a Loader type
      @create_records = policy_version.create_records.map do |policy_object|
        Loader::Types.wrap(policy_object, self, transaction_id)
      end
      Rails.logger.info("+++++++++++ Orchestrate::initialize 3 transaction id = #{transaction_id}")
      @delete_records = policy_version.delete_records.map do |policy_object|
        Loader::Types.wrap(policy_object, self, transaction_id)
      end
      Rails.logger.info("+++++++++++ Orchestrate::initialize 4 transaction id = #{transaction_id}")
      #changed_records[transaction_id].concat("]")
      #Rails.logger.info("+++++++++++ Orchestrate::initialize changed_records[transaction_id] = #{changed_records[transaction_id]}")
    end

    #def add_record_message(transaction_id, record_message)
      #changed_records[transaction_id].concat(record_message)



    # Gets the id of the policy being loaded.
    def policy_id
      policy_version.policy.id
    end

    def setup_db_for_new_policy
      # We use the db setup to signal the start of a policy load
      if @feature_flags.enabled?(:policy_load_extensions)
        @extensions.call(:before_load_policy, policy_version: @policy_version)
      end

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
        disable_policy_log_trigger
        TABLES.each { |table| insert_table_records(table) }
        enable_policy_log_trigger
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

    #$region = 'us-east-2'
    #$sqs_client = Aws::SQS::Client.new(region: $region, verify_checksums: false)
    #$message_id=0

    def publish_changes
      #$message_id = rand(1..100000)

      transaction_message = "{ \"entities\": [ "
      @create_records = policy_version.create_records.map do |policy_object|
        entity_message = "{ \"" + policy_object.class.name + "\" : { \"action\": \"set\", \"data\": " + policy_object.to_json() + "}}"
        Rails.logger.info("+++++++++ publish_changes 1 entity_message = #{entity_message}")
        transaction_message = transaction_message + entity_message + ","
      end
      @delete_records = policy_version.delete_records.map do |policy_object|
        entity_message = "{ \"" + policy_object.class.name + "\" : { \"action\": \"delete\", \"data\": " + policy_object.to_json() + "}}"
        Rails.logger.info("+++++++++ publish_changes 2 entity_message = #{entity_message}")
        transaction_message = transaction_message + entity_message + ","
      end
      transaction_message = transaction_message + "{\"end\": " + $message_id.to_s + "} ] }"

      publisher = Conjur::SqsPublishUtils.new()
      publisher.send_message(transaction_message)
      #region = 'us-east-2'
      #queue_name = 'OfiraConjurEdgeQueue.fifo'
      #Rails.logger.info("+++++++++ publish_changes 4")
      #Rails.logger.info("+++++++++ publish_changes 5 transaction_message = #{transaction_message}")
      #queue_url = 'https://sqs.' + region + '.amazonaws.com/' +
      #  '238637036211' + '/' + queue_name

      #Rails.logger.info("+++++++++ Sending a message to the queue named '#{queue_name}'...")

      #resp1 = $sqs_client.send_message(
      #      queue_url: queue_url,
      #      message_body: transaction_message, # "transaction_message" + $message_id.to_s,
      #      message_group_id: 'message_group_id')
      #Rails.logger.info("+++++++++ publish 5.1 resp1 = #{resp1}, message_id =#{$message_id}")
      #Rails.logger.info("+++++++++ Sending a message to the queue named '#{queue_name}'...")
      #Rails.logger.info("+++++++++ publish_changes 7")
    end

    # Loads the records into the temporary schema (since the schema search path
    # contains only the temporary schema).
    def load_records
      raise "Policy version must be saved before loading" unless policy_version.resource_id

      Rails.logger.info("+++++++++ load_records 1")
      create_records.map(&:create!)
      #db.after_commit {
      #  Rails.logger.info("+++++++++ load_records after commit")
      #  publish_changes
      #  raise "This is an exception"
      #}
      Rails.logger.info("+++++++++ load_records 2")
      db[:role_memberships].where(admin_option: nil).update(admin_option: false)
      db[:role_memberships].where(ownership: nil).update(ownership: false)
      Rails.logger.info("+++++++++ load_records 3")
      TABLES.each do |table|
        Rails.logger.info("+++++++++ load_records 4")
        db[table].update(policy_id: policy_version.resource_id)
      end

      Rails.logger.info("+++++++++ load_records 5")
      publish_changes
      #raise "This is an exception"
      Rails.logger.info("+++++++++ load_records 7")

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
  end
  # rubocop:enable Metrics/ClassLength
end
