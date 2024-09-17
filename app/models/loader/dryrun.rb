# frozen_string_literal: true

# (The Conjur base uses both hash styles; byebug prints using old style
# so it's helpful to have the same style used in the source.)
# rubocop:disable Style/HashSyntax

module Loader
  #
  # DiffElementsDTO is an interface providing access to policy diff results,
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
  #
  class DiffElementsDTO
    attr_reader :diff_type, :roles, :resources, :role_memberships, :permissions,
                :annotations, :credentials
    attr_writer :roles, :resources, :role_memberships, :permissions,
                :annotations, :credentials

    def initialize(
      diff_type: nil
    )
      @diff_type = diff_type
      @roles = nil
      @role_memberships = nil
      @credentials = nil
      @resources = nil
      @permissions = nil
      @annotations = nil
    end

    # Provide reference to each of the policy tables.
    # The row "elements" are returned as hashes.
    # Note: for security reasons only a subset of columns may be
    # available through the DTO, though none are currently withheld

    def all_elements
      {
        :annotations => annotations,
        :permissions => permissions,
        :resources => resources,
        :role_memberships => role_memberships,
        :roles => roles,
        :credentials => credentials
      }
    end
  end

  # DryRun loads a policy using the interface of Loader::Orchestrate,
  # but interpreting it to produce a dry-run simulation of what the
  # resulting policy would be.

  # Performance Considerations:
  #
  # Diff comparisons
  #
  #   TODO: these could be more dynamic, but we want to ensure that the
  #   results are sorted, and I'm too lazy to determine how to do that. Perhaps
  #   with the utilization of TABLE_EQUIVALENCE values? Then all of these
  #   become 2 methods, 1 for create, and 1 for delete, each taking a table
  #   name...
  #
  # Memory Usage
  #
  #   Optimize scheduling of queries and reports:
  #   In get_diff we run all of the 3 sets of queries and save their
  #   results until report time, incurring a memory penalty while
  #   holding all these results.
  #   We could instead generate the reports one by one, reducing the
  #   peak memory usage, by scheduling the operations like this:

  #     1. diff.created , report.created , release results
  #     2. diff.deleted , report.deleted , release results

  # (Much of the class length comes because of its many SQL statements.)
  # rubocop:disable Metrics/ClassLength
  #
  class DryRun < Orchestrate
    def initialize(
          policy_parse:,
          policy_version:,
          logger: Rails.logger
        )
      super
    end

    # Determines the Raw Diff results, calculated using SQL operations and
    # returned to clients organized by created and deleted schemas.
    #
    # - When called, the 'load' policy operation has already been performed
    # - Upon return, each of the DTO result access functions are
    #   available for use.
    #
    # Each function here performs diffs on the 'before' and 'after' schemas,
    # saves the results by type of diff performed, and makes the results
    # available by a DTO interface referenced by the diff operation:
    #   :created, deleted

    def get_diff
      # Compare the two schemas to determine the sets of created and
      # deleted elements.  Provide DTOs for each type, each
      # with its own query store.
      created_elements_dto = select_created_elements
      deleted_elements_dto = select_deleted_elements

      # Return a hash of references to the DTOs
      {
        "created": created_elements_dto,
        "deleted": deleted_elements_dto
      }
    end

    private

    def select_created_elements
      original = public_schema_before_changes
      changed = primary_schema

      created = DiffElementsDTO.new(diff_type: "created")

      created.annotations = annotations_unique_to_b(original, changed)
      created.permissions = permissions_unique_to_b(original, changed)
      created.resources = resources_unique_to_b(original, changed)
      created.role_memberships = role_memberships_unique_to_b(original, changed)
      created.roles = roles_unique_to_b(original, changed)
      created.credentials = credentials_unique_to_b(original, changed)

      created
    end

    def select_deleted_elements
      original = public_schema_before_changes
      changed = primary_schema

      deleted = DiffElementsDTO.new(diff_type: "deleted")

      deleted.annotations = annotations_unique_to_b(changed, original)
      deleted.permissions = permissions_unique_to_b(changed, original)
      deleted.resources = resources_unique_to_b(changed, original)
      deleted.role_memberships = role_memberships_unique_to_b(changed, original)
      deleted.roles = roles_unique_to_b(changed, original)
      deleted.credentials = credentials_unique_to_b(changed, original)

      deleted
    end

    protected

    # Determining the "created" and "deleted" elements:
    #
    # - Use the schemas from "before" and "after" policy loading.
    #
    # - Given sets A and B, their intersection c, and non-intersections a and b:
    #   the unique "created" set "b" results when A is "before" elements and
    #   B is the "after" elements.
    #
    # - Similarly, the unique "deleted" set "a" results when A is "before" and
    #   B is "after".
    #
    #   A       B
    # +----+ +----+   b = SELECT * FROM B EXCEPT (SELECT * FROM A)
    # | a ( c ) b |
    # +----+ +----+   a = SELECT * FROM A EXCEPT (SELECT * FROM B)
    #

    # annotations
    # COLUMNS     {:resource_id, :name, :value, :policy_id}
    # KEY FIELDS  {:resource_id, :name, :value}

    def annotations_unique_to_b(set_a, set_b)
      query = <<-SQL
        SELECT * FROM #{set_b}.annotations
        EXCEPT
        SELECT * FROM #{set_a}.annotations
        ORDER BY resource_id, name;
      SQL
      db.fetch(query).all
    end

    # permissions
    # COLUMNS     {:resource_id, :privilege, :role_id, :policy_id}
    # KEY FIELDS  {:resource_id, :privilege, :role_id}

    def permissions_unique_to_b(set_a, set_b)
      query = <<-SQL
        SELECT * FROM #{set_b}.permissions
        EXCEPT
        SELECT * FROM #{set_a}.permissions
        ORDER BY resource_id, role_id, privilege;
      SQL
      db.fetch(query).all
    end

    # resources
    # COLUMNS     {:resource_id, :owner_id, :created_at, :policy_id}
    # KEY FIELDS  {:resource_id, :owner_id}

    def resources_unique_to_b(set_a, set_b)
      query = <<-SQL
        SELECT * FROM #{set_b}.resources
        EXCEPT
        SELECT * FROM #{set_a}.resources
        ORDER BY policy_id, resource_id, owner_id;
      SQL
      db.fetch(query).all
    end

    # role_memberships
    # COLUMNS     {:role_id, :member_id, :admin_option, :ownership, :policy_id}
    # KEY FIELDS  {:role_id, :member_id, :admin_option, :ownership}

    def role_memberships_unique_to_b(set_a, set_b)
      query = <<-SQL
        SELECT * FROM #{set_b}.role_memberships
        EXCEPT
        SELECT * FROM #{set_a}.role_memberships
        ORDER BY role_id, member_id;
      SQL
      db.fetch(query).all
    end

    # roles
    # COLUMNS     {:role_id, :created_at, :policy_id}
    # KEY FIELDS  {:role_id}

    def roles_unique_to_b(set_a, set_b)
      query = <<-SQL
        SELECT * FROM #{set_b}.roles
        EXCEPT
        SELECT * FROM #{set_a}.roles
        ORDER BY role_id;
      SQL
      db.fetch(query).all
    end

    # credentials
    # Security note: ONLY the 3 columns listed are queried.
    # COLUMNS     {:role_id, :client_id, :restricted_to}
    # KEY FIELDS

    def credentials_unique_to_b(set_a, set_b)
      query = <<-SQL
        SELECT role_id, client_id, restricted_to FROM #{set_b}.credentials
        EXCEPT
        SELECT role_id, client_id, restricted_to FROM #{set_a}.credentials
        ORDER BY role_id;
      SQL
      db.fetch(query).all
    end

    # Schema management

    public

    # Create a unique name for the "before" schema
    # ("before" meaning, before application of the dry-run policy)
    #
    # (The .first method is NOT wanted, and breaks the function)
    # rubocop:disable Style/UnpackFirst
    def public_schema_before_changes
      @random ||= Random.new
      rnd = @random.bytes(8).unpack('h*').first
      @public_schema_before_changes ||= "policy_loader_before_#{rnd}"
    end
    # rubocop:enable Style/UnpackFirst

    # Capture the schema (state of all its tables)
    # (Using double-quotes because using string interpolation)
    # rubocop:disable Style/StringLiteralsInInterpolation
    # (The method is logically concise but lengthy due to SQL expansion)
    # rubocop:disable Metrics/MethodLength
    def snapshot_public_schema_before
      schema_name = public_schema_before_changes
      # Create the "before" state from a fresh, uniquely-named schema
      db.execute("DROP SCHEMA IF EXISTS #{schema_name} CASCADE")
      db.execute("CREATE SCHEMA #{schema_name}")
      db.search_path = schema_name

      # Create the "before" TABLES matching current public schema
      TABLES.each do |table|
        db.execute(<<-SQL_STATEMENT)
          CREATE TABLE #{table}
          AS SELECT *
          FROM #{qualify_table(table)} WHERE 0 = 1;
        SQL_STATEMENT
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

      db.execute(<<-SQL_STATEMENT)
        ALTER TABLE role_memberships
        ALTER COLUMN admin_option SET DEFAULT 'f';
      SQL_STATEMENT

      # Clone public schema content into new tables
      TABLES.each do |table|
        db.execute(<<-SQL_STATEMENT)
          INSERT INTO #{table} SELECT *
          FROM #{qualify_table(table)};
        SQL_STATEMENT
      end

      # Store the credentials for public schema
      db.execute(<<-SQL_STATEMENT)
        CREATE TABLE credentials
        AS SELECT role_id, client_id, restricted_to
        FROM #{qualify_table("credentials")} WHERE 0 = 1;
      SQL_STATEMENT

      db.execute(<<-SQL_STATEMENT)
        INSERT INTO credentials
        SELECT role_id, client_id, restricted_to
        FROM #{qualify_table("credentials")};
      SQL_STATEMENT

      # Done
      restore_search_path
      # print_debug
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Style/StringLiteralsInInterpolation

    def drop_snapshot_public_schema_before
      db.execute("DROP SCHEMA #{public_schema_before_changes} CASCADE")
    end

    # Returns the syntax / business logic validation report interface
    # (This method will condense once when the feature slices are completed,
    # and several rubocop warnings should vanish.)
    def report(policy_result)
      # Fetch
      error = policy_result.error
      version = policy_result.policy_version
      roles = policy_result.created_roles
      diff = policy_result.diff

      # Hydrate
      # TODO: this presupposes that dry-run diff processing
      # would return results in the created_roles and diff components, and then
      # extraction from those components populates the 'items' array.
      # The actual implementation will be different,
      # and those steps may occur elsewhere.

      status = error ? "Invalid YAML" : "Valid YAML"
      # includes enhanced error info
      errors = error ? [error.as_validation] : []

      items = []

      initial = {
        "items" => items.length ? items : []
      }
      final = {
        "items" => items.length ? items : []
      }
      created = {
        "items" => items.length ? items : []
      }
      updated = {
        "before" => initial,
        "after" => final
      }
      deleted = {
        "items" => items.length ? items : []
      }

      # API response format follows "Policy Dry Run v2 Solution Design"
      if error
        response = {
          "status" => status,
          "errors" => errors
        }
      else
        response = {
          "status" => status,
          "created" => created,
          "updated" => updated,
          "deleted" => deleted
        }
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end

# rubocop:enable Style/HashSyntax
