module DB
  module Utils
    class MaterializedViews
      def initialize(
        db: Sequel::Model.db,
        logger: Rails.logger
      )
        @db = db
        @logger = logger
      end

      def refresh()
        @logger.debug("Begin refreshing materialized views...")
        refresh_all_roles
        refresh_resources
        @logger.debug("Finished refreshing materialized views.")
      end

      def refresh_all_roles()
        @db.run('REFRESH MATERIALIZED VIEW all_roles_view;')
      rescue Sequel::DatabaseError => e
        # TODO: handle ERROR:  relation "all_roles_view" does not exist
        # /var/lib/ruby/lib/ruby/gems/3.0.0/gems/sequel-5.51.0/lib/sequel/adapters/postgres.rb:156:in `exec': ERROR:  relation "all_roles_view" does not exist (PG::UndefinedTable)
        # ...
        @logger.error(
          "DB::Utils::MaterializedViews.refresh_all_roles - Error #{e.message}"
        )
      end

      def refresh_resources()
        @db.run('REFRESH MATERIALIZED VIEW resources_view;')
      rescue Sequel::DatabaseError => e
        # TODO: handle ERROR:  relation "resources_view" does not exist
        # /var/lib/ruby/lib/ruby/gems/3.0.0/gems/sequel-5.51.0/lib/sequel/adapters/postgres.rb:156:in `exec': ERROR:  relation "all_roles_view" does not exist (PG::UndefinedTable)
        # ...
        @logger.error(
          "DB::Utils::MaterializedViews.refresh_resources - Error #{e.message}"
        )
      end     
    end
  end
end
