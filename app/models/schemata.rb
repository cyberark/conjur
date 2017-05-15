class Schemata
  @@search_path = nil
  @@primary_schema = nil

  class << self
    def initialize_schemata
      @@search_path = Sequel::Model.db.search_path

      # Verify that all schemata in the search path actually exist, except the automatic entry "$user"
      @@search_path.each do |schema|
        next if schema == :"$user"
        raise "Schema #{schema.inspect} from the search path is not listed current_schemas(false)" unless Sequel::Model.db.current_schemata.member?(schema)
      end

      # Verify that there is a primary schema in the DB
      primary_schema = db.select(Sequel::function(:current_schema)).single_value
      raise "No primary schema is available from search path #{search_path.inspect}" if primary_schema.nil?

      Rails.logger.info "Primary schema is #{primary_schema.inspect}"
      @@primary_schema = primary_schema.to_sym
    end

    def search_path
      @@search_path or raise "Schema search path has not been configured"
    end

    def primary_schema
      @@primary_schema or raise "Primary schema has not been configured"
    end

    def db
      Sequel::Model.db
    end
  end

  module Helper
    def primary_schema
      Schemata.primary_schema
    end

    def model_for_table table
      Sequel::Model [ primary_schema, table ].join("__").to_sym
    end

    def qualify_table table, separator: "."
      [ primary_schema, table].join(separator)
    end

    def restore_search_path
      db.search_path = Schemata.search_path
    end
  end
end
