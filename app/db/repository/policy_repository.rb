# frozen_string_literal: true

module DB
  module Repository
    module DataObjects
      # DiffElements is an interface providing access to policy diff results,
      # with methods for each of the schema tables.
      # (For the sake of abstraction we're calling them "elements" instead of rows).
      # The write accessors support initialization by the Raw Diff operation and the
      # read accessors are intended for the Mapping operation.
      # It's intended that there be one DTO for each of the diff comparisons, e.g.
      # created_dto, deleted_dto.
      #
      # Background: as originally conceived the attribute methods might
      # have involved non-trivial access because the underlying data type
      # (now hash) wasn't yet decided, thus a class was provided to leave open
      # the possibility of access via methods.  The credentials field may yet
      # require some means of conditional access.
      class DiffElements
        attr_accessor :roles, :resources, :role_memberships, :permissions, :annotations, :credentials
        attr_reader :diff_type

        def initialize(
          diff_type: nil,
          annotations: nil,
          credentials: nil,
          permissions: nil,
          resources: nil,
          role_memberships: nil,
          roles: nil
        )
          @diff_type = diff_type
          @annotations = annotations
          @credentials = credentials
          @permissions = permissions
          @resources = resources
          @role_memberships = role_memberships
          @roles = roles
        end

        # Provide reference to each of the policy tables.
        # The row "elements" are returned as hashes.
        # Note: for security reasons only a subset of columns may be
        # available through the DTO, though none are currently withheld
        def all_elements
          {
            annotations: annotations,
            credentials: credentials,
            permissions: permissions,
            resources: resources,
            role_memberships: role_memberships,
            roles: roles
          }
        end
      end
    end

    class PolicyRepository
      include Schemata::Helper
      attr_reader :schemata

      TABLES = %i[roles role_memberships resources permissions annotations credentials].freeze

      #
      # Given two existing schemas with the same tables, this class provides a
      # means to compare them, offering the ability to:
      #
      # 1. Find the table rows that are unique to either schema
      # 2. Obtain the original state of a resource that has been updated
      #
      def initialize(
        data_object: DataObjects::DiffElements,
        db: Sequel::Model.db,
        logger: Rails.logger,
        schemata: Schemata.new
      )
        @data_object = data_object
        @db = db
        @logger = logger
        @schemata = schemata
        @success = ::SuccessResponse
        @failure = ::FailureResponse
      end

      def schema_after_changes
        @schemata.primary_schema
      end

      # TODO: As a part of CNJR-6965, this method can become a private method.
      #
      # Capture the public schema (state of all its tables) for a dryrun.
      # (Using double-quotes because using string interpolation)
      # rubocop:disable Style/StringLiteralsInInterpolation
      # (The method is logically concise but lengthy due to SQL expansion)
      def setup_schema_for_dryrun_diff(diff_schema_name:)
        tables_except_credentials = TABLES - [:credentials]

        # Create the "before" state from a fresh, uniquely-named schema
        @db.execute("DROP SCHEMA IF EXISTS #{diff_schema_name} CASCADE")
        @db.execute("CREATE SCHEMA #{diff_schema_name}")
        @db.search_path = diff_schema_name

        # Create the "before" TABLES matching current public schema
        tables_except_credentials.each do |table|
          @db.execute(<<-SQL_STATEMENT)
            CREATE TABLE #{table}
            AS SELECT *
            FROM #{qualify_table(table)} WHERE 0 = 1;
          SQL_STATEMENT
        end

        @db.execute(Functions.ownership_trigger_sql)

        @db.execute(<<-SQL_STATEMENT)
          CREATE OR REPLACE FUNCTION account(id text) RETURNS text
          LANGUAGE sql IMMUTABLE
          AS $$
          SELECT CASE
            WHEN split_part($1, ':', 1) = '' THEN NULL
            ELSE split_part($1, ':', 1)
          END
          $$;
        SQL_STATEMENT

        @db.execute("ALTER TABLE resources ADD PRIMARY KEY ( resource_id )")
        @db.execute("ALTER TABLE roles ADD PRIMARY KEY ( role_id )")

        @db.execute(<<-SQL_STATEMENT)
          ALTER TABLE role_memberships
          ALTER COLUMN admin_option SET DEFAULT 'f';
        SQL_STATEMENT

        # Clone public schema content into new tables
        tables_except_credentials.each do |table|
          @db.execute(<<-SQL_STATEMENT)
            INSERT INTO #{table} SELECT *
            FROM #{qualify_table(table)};
          SQL_STATEMENT
        end

        # Store the credentials for public schema
        @db.execute(<<-SQL_STATEMENT)
          CREATE TABLE credentials
          AS SELECT role_id, client_id, restricted_to
          FROM #{qualify_table("credentials")} WHERE 0 = 1;
        SQL_STATEMENT

        @db.execute(<<-SQL_STATEMENT)
          INSERT INTO credentials
          SELECT role_id, client_id, restricted_to
          FROM #{qualify_table("credentials")};
        SQL_STATEMENT

        # Used to determine which resources have been "updated"
        @db.execute("CREATE TABLE updated_resources (resource_id text);")
        @db.execute("CREATE INDEX idx_resource_id ON updated_resources (resource_id);")

        # Done
        @schemata.restore_search_path
        # print_debug
      end
      # rubocop:enable Style/StringLiteralsInInterpolation

      # TODO: As a part of CNJR-6965, this method can become a private method.
      def drop_diff_schema_for_dryrun(diff_schema_name:)
        @db.execute("DROP SCHEMA #{diff_schema_name} CASCADE")
      end

      def find_created_elements(diff_schema_name:)
        original = diff_schema_name
        changed = schema_after_changes
  
        @success.new(
          @data_object.new(
            diff_type: 'created',
            annotations: find_unique_to_b(
              table_name: :annotations,
              schema_a: original,
              schema_b: changed
            ),
            permissions: find_unique_to_b(
              table_name: :permissions,
              schema_a: original,
              schema_b: changed
            ),
            resources: find_unique_to_b(
              table_name: :resources,
              schema_a: original,
              schema_b: changed
            ),
            role_memberships: find_unique_to_b(
              table_name: :role_memberships,
              schema_a: original,
              schema_b: changed
            ),
            roles: find_unique_to_b(
              table_name: :roles,
              schema_a: original,
              schema_b: changed
            ),
            credentials: find_unique_to_b(
              table_name: :credentials,
              schema_a: original,
              schema_b: changed
            )
          )
        )
      end

      def find_deleted_elements(diff_schema_name:)
        original = diff_schema_name
        changed = schema_after_changes

        @success.new(
          @data_object.new(
            diff_type: 'deleted',
            annotations: find_unique_to_b(
              table_name: :annotations,
              schema_a: changed,
              schema_b: original
            ),
            permissions: find_unique_to_b(
              table_name: :permissions,
              schema_a: changed,
              schema_b: original
            ),
            resources: find_unique_to_b(
              table_name: :resources,
              schema_a: changed,
              schema_b: original
            ),
            role_memberships: find_unique_to_b(
              table_name: :role_memberships,
              schema_a: changed,
              schema_b: original
            ),
            roles: find_unique_to_b(
              table_name: :roles,
              schema_a: changed,
              schema_b: original
            ),
            credentials: find_unique_to_b(
              table_name: :credentials,
              schema_a: changed,
              schema_b: original
            )
          )
        )
      end

      def find_original_elements(diff_schema_name:)
        original = diff_schema_name
        changed = schema_after_changes

        # Determine which conjur resources have been updated
        set_updated_resources_ids(original_schema: original, changed_schema: changed)

        # Actually find the original elements
        @success.new(
          @data_object.new(
            diff_type: 'updated',
            annotations: find_original_elements_for_table(
              table_name: :annotations,
              original_schema: original
            ),
            permissions: find_original_elements_for_table(
              table_name: :permissions,
              original_schema: original
            ),
            resources: find_original_elements_for_table(
              table_name: :resources,
              original_schema: original
            ),
            role_memberships: find_original_elements_for_table(
              table_name: :role_memberships,
              original_schema: original
            ),
            roles: find_original_elements_for_table(
              table_name: :roles,
              original_schema: original
            ),
            credentials: find_original_elements_for_table(
              table_name: :credentials,
              original_schema: original
            )
          )
        )
      end

      private

      def excluded_columns
        # The tables in the temp schema does not contain these columns, or
        # they are not pertinent to the diff operation.
        {
          credentials: %i[api_key created_at encrypted_hash expiration],
          resources: %i[created_at],
          roles: %i[created_at]
        }
      end

      # The order of primary keys is not significant in the query, however, to
      # aid in readability in the case of permissions, we prefer this order.
      def pks_preferred_order 
        %i[resource_id role_id member_id]
      end

      # Returns the name of the temp table used to store the ids of resources
      # who have been determined to be updated. This should only be present in
      # the temporary schema used during the dry run.
      def updated_resources_table_name
        "updated_resources"
      end

      # Returns the rows for that are unique to schema b for a given table.
      # This can be used to determine the "created" and "deleted" elements
      # between the same tables across two different schemas, depending on the
      # order of the schemas passed in.
      #
      # - Use the schemas from "before" and "after" policy loading.
      #
      # - Given sets A and B, their intersection c, and non-intersections a and b:
      #   the unique "created" set "b" results when A is "before" elements and
      #   B is the "after" elements.
      #
      #   A       B
      # +----+ +----+   b = SELECT * FROM B EXCEPT (SELECT * FROM A)
      # | a ( c ) b |
      # +----+ +----+   a = SELECT * FROM A EXCEPT (SELECT * FROM B)
      #
      def find_unique_to_b(table_name:, schema_a:, schema_b:)
        query = generate_unique_to_b_query(
          table_name: table_name,
          schema_a: schema_a,
          schema_b: schema_b
        )    
        @db.fetch(query).all
      end

      def generate_unique_to_b_query(table_name:, schema_a:, schema_b:, terminate: true)
        model = model_for_table(table_name)
        pks = Array(model.primary_key)
        pks = reorder_array(array: pks, preferred_order: pks_preferred_order)
        cols = model.columns - (excluded_columns[table_name.to_sym] || [])

        query = <<~SQL.strip
          SELECT #{cols.map(&:to_s).join(', ')} FROM #{schema_b}.#{table_name}
          EXCEPT
          SELECT #{cols.map(&:to_s).join(', ')} FROM #{schema_a}.#{table_name}
          ORDER BY #{pks.map(&:to_s).join(', ')}
        SQL

        terminate ? "#{query.strip};" : query.strip
      end

      # Returns a SQL query that will populate the updated_resources table with
      # any resource_id who is referenced in any TABLES that has been updated
      # in either of the schemas.
      #
      # This query consists of 3 parts:
      # 1. CTEs for each table whose that are unique to schema A
      # 2. CTEs for each table whose that are unique to schema B
      # 3. A UNION of all the unique resource_ids from the CTEs
      def generate_find_and_save_updated_resources_query(original_schema:, changed_schema:)
        sql_unique_to_a = {}
        sql_unique_to_b = {}
        sql_union_a_and_b = []

        TABLES.each do |table_name|
          sql_unique_to_a[table_name] ||= []
          sql_unique_to_b[table_name] ||= []
          
          # Part 1
          sql_unique_to_a[table_name] << generate_unique_to_b_query(
            table_name: table_name,
            schema_a: changed_schema,
            schema_b: original_schema,
            terminate: false
          )

          # Part 2
          sql_unique_to_b[table_name] << generate_unique_to_b_query(
            table_name: table_name,
            schema_a: original_schema,
            schema_b: changed_schema,
            terminate: false
          )

          # Part 3
          sql_union_a_and_b.concat(generate_union_queries_for_updated_resources(table_name: table_name))
        end

        # Consolidate these query parts into a single query
        generate_insert_query_for_updated_resources(
          original_schema: original_schema,
          sql_unique_to_a: sql_unique_to_a,
          sql_unique_to_b: sql_unique_to_b,
          sql_union_a_and_b: sql_union_a_and_b
        )
      end

      # Returns a list of SQL queries that UNION the two sets of data from the
      # CTEs built by generate_find_and_save_updated_resources_query.
      def generate_union_queries_for_updated_resources(table_name:)
        # We only leverage a PK or component of a Composite Key that is a
        # resource_id (role_id, member_id, etc.)
        included_pks = %i[resource_id role_id member_id]
        model = model_for_table(table_name)
        pks = Array(model.primary_key).map(&:to_sym) & included_pks

        pks.map do |pk|
          <<~SQL
            SELECT #{pk} AS resource_id FROM cte_#{table_name}_unique_to_a
            UNION
            SELECT #{pk} AS resource_id FROM cte_#{table_name}_unique_to_b
          SQL
        end
      end

      # Returns a single query that is a consolidation of the query parts
      # assembled by the calling function.
      def generate_insert_query_for_updated_resources(original_schema:, sql_unique_to_a:, sql_unique_to_b:, sql_union_a_and_b:)
        <<~SQL
          INSERT INTO #{original_schema}.#{updated_resources_table_name} (resource_id)
          WITH #{
            sql_unique_to_a.flat_map do |table_name, queries|
              queries.map do |q|
                "cte_#{table_name}_unique_to_a AS (\n#{q})"
              end
            end.join(', ')
          },
          #{
            sql_unique_to_b.flat_map do |table_name, queries|
              queries.map do |q|
                "cte_#{table_name}_unique_to_b AS (\n#{q})"
              end
            end.join(', ')
          }
          #{sql_union_a_and_b.join("UNION\n")};
        SQL
      end

      # Populates the updated_resources table in the temp schema with a list
      # of resource_ids of resources that have been "updated". A role/resource
      # has been updated if an attribute has been created or deleted on an
      # existing resource.
      def set_updated_resources_ids(original_schema:, changed_schema:)
        query = generate_find_and_save_updated_resources_query(
          original_schema: original_schema,
          changed_schema: changed_schema
        )
        @db.execute(query)
      end

      # Returns the original (non-updated) elements of a conjur resource that
      # has been updated. i.e.) the original state of a conjur resource prior
      # to applying the dry run.
      def find_original_elements_for_table(table_name:, original_schema:)
        model = model_for_table(table_name)
        pks = Array(model.primary_key)
        pks = reorder_array(array: pks, preferred_order: pks_preferred_order)
        cols = model.columns - (excluded_columns[table_name.to_sym] || [])

        query = generate_original_elements_for_table_query(
          original_schema: original_schema,
          table_name: table_name,
          columns: cols,
          primary_keys: pks
        )

        @db.fetch(query).all
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

      def generate_original_elements_for_table_query(original_schema:, table_name:, columns:, primary_keys:)
        <<~SQL
          SELECT DISTINCT #{columns.map { |col| "a.#{col}" }.join(', ')}
          FROM #{original_schema}.#{table_name} a
          #{generate_join_statement_for_original_resources(table_name: table_name, original_schema: original_schema)}
          ORDER BY #{primary_keys.map { |pk| "a.#{pk}" }.join(', ')};
        SQL
      end

      def generate_join_statement_for_original_resources(table_name:, original_schema:)
        table_join_map = {
          annotations: %i[resource_id],
          resources: %i[resource_id],
          roles: %i[role_id],
          credentials: %i[role_id],
          permissions: %i[resource_id role_id],
          role_memberships: %i[role_id member_id]
        }

        join_conditions = table_join_map[table_name].map { |key| "a.#{key} = b.resource_id" }.join(' OR ')

        <<~SQL.strip
          JOIN #{original_schema}.#{updated_resources_table_name} b
          ON #{join_conditions}
        SQL
      end
    end
  end
end
