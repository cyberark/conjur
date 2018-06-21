require 'pg'

module Rotation
  module Rotators
    module Postgresql

      class Password

        def initialize(password_factory: ::Rotation::Base58Password, pg: ::PG)
          @password_factory = password_factory
          @pg = pg
        end

        # 1. Generate new pw
        # 2. Update of variable in Conjur.
        # 3. Update variable in the DB itself.
        #
        # NOTE: Both 2 and 3 are executed inside a single transaction, so either
        #       both updates happen, or neither do.
        #
        def rotate(facade)
          resource_id = facade.rotated_variable.resource_id
          db          = rotated_db(facade)
          return if db.missing_values?
          new_pw      = db.new_password
          pw_update   = Hash[resource_id, new_pw]

          p "******************************************************"
          p "******************************************************"
          p "Rotating #{new_pw}"
          facade.update_variables(pw_update) do
            p "#######################################"
            p "executing..."
            db.update_password(new_pw)
            p "done"
          end
        end

        private

        def rotated_db(facade)
          RotatedDb.new(facade, @pg, @password_factory)
        end

        class RotatedDb

          def initialize(facade, pg, password_factory)
            @facade = facade
            @pg = pg
            @password_factory = password_factory
            # cache existing creditials
            db_uri
          end

          def missing_values?
            credentials.values.compact.size < 3
          end

          def new_password
            @password_factory.new(length: pw_length)
          end

          def update_password(new_pw)
            conn = connection
            conn.exec("ALTER ROLE #{username} WITH PASSWORD '#{new_pw}'")
            conn.close
          end

          def connection
            puts "db_uri", db_uri
            connection = @pg.connect(db_uri)
            connection.exec('SELECT 1')
            connection
          end

          def db_uri
            return @db_uri if @db_uri
            puts "credentials", credentials
            url, uname, password = credential_resource_ids.map(&credentials)
            @db_uri = "postgresql://#{uname}:#{password}@#{url}"
          end

          private

          def username
            credentials[username_id]
          end

          def credentials
            @credentials ||= @facade.current_values(credential_resource_ids)
          end

          def credential_resource_ids
            [url_id, username_id, password_id]
          end

          def rotated_variable
            @facade.rotated_variable
          end

          def pw_length
            @facade.annotations['rotation/postgresql/password/length'].to_i || 20
          end

          def password_id
            rotated_variable.resource_id
          end

          def url_id
            rotated_variable.sibling_id('url')
          end

          def username_id
            rotated_variable.sibling_id('username')
          end
        end

      end

    end
  end
end
