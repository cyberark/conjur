# frozen_string_literal: true

# Manages the schema search path and identifies the primary schema (the one to which 
# SQL and DDL operations will apply by default).
#
# The default Postgresql schema search path is "$user, public", where the "$user"
# indicates a schema whose name matches the authenticated user. If the $user schema
# doesn't exist, it is ignored. As a result, SQL and DDL operations normally apply 
# to the "public" schema unless a schema is indicated specifically (e.g. "myschema.mytable").
#
# Conjur can be configured with an alternative search path, such as "conjur, public". In this case,
# DDL and SQL will be applied to the primary schema (in this example, "conjur").
#
# If Conjur is run with an alternative primary schema, it's the responsibility of the
# operator to create that schema and grant the necessary privileges to the database user.
class Schemata
  attr_reader :search_path, :primary_schema

  def initialize
    @search_path = Sequel::Model.db.search_path

    # Verify that all schemata in the search path actually exist, except the
    # automatic entry "$user"
    @search_path.each do |schema|
      next if schema == :"$user"
      unless Sequel::Model.db.current_schemata.member?(schema)
        raise "Schema #{schema.inspect} from the search path is not listed " \
          "current_schemas(false)"
      end
    end

    # Verify that there is a primary schema in the DB
    primary_schema = db.select(
      Sequel::function(:current_schema)
    ).single_value

    if primary_schema.nil?
      raise "No primary schema is available from search path "\
        "#{search_path.inspect}"
    end

    Rails.logger.info(
      LogMessages::Conjur::PrimarySchema.new(primary_schema.inspect)
    )

    @primary_schema = primary_schema.to_sym
  end

  module Helper
    def primary_schema
      schemata.primary_schema
    end

    def model_for_table table
      Sequel::Model [ primary_schema, table ].join("__").to_sym
    end

    def qualify_table table, separator: "."
      [ primary_schema, table].join(separator)
    end

    def restore_search_path
      db.search_path = schemata.search_path
    end

    def model_for_table table
      Sequel::Model [ primary_schema, table ].join("__").to_sym
    end
  end

  def qualify_table table, separator: "."
    [ primary_schema, table].join(separator)
  end

  def restore_search_path
    db.search_path = self.search_path
  end

  protected

  def db
    Sequel::Model.db
  end
end
