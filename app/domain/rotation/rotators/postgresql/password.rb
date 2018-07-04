# frozen_string_literal: true

require 'pg'

module Rotation
  module Rotators
    module Postgresql

      class Password

        PASSWORD_LENGTH_ANNOTATION = 'rotation/postgresql/password/length'

        def initialize(password_factory: ::Rotation::Password, pg: ::PG)
          @password_factory = password_factory
          @pg = pg
        end

        # 1. Generate new pw
        # 2. Update variable in Conjur.
        # 3. Update variable in the DB itself.
        #
        # NOTE: Both 2 and 3 are executed inside a single transaction, so either
        #       both updates happen, or neither do.
        #  
        # NOTE: The order matters:
        #       1. Capture the *current* credentials
        #       2. The Database object `db` then uses those to perform the
        #          update to the new credentials.
        #
        def rotate(facade)

          resource_id = facade.rotated_variable.resource_id
          credentials = DbCredentials.new(facade)
          new_pw      = new_password(facade)
          db          = Database.new(credentials, @pg)
          pw_update   = Hash[resource_id, new_pw]

          facade.update_variables(pw_update) do
            db.update_password(new_pw)
          end
        end

        private

        def new_password(facade)
          @password_factory.base58(length: pw_length(facade))
        end

        def pw_length(facade)
          @pw_length ||= facade.annotations[PASSWORD_LENGTH_ANNOTATION].to_i || 20
        end

        class DbCredentials

          # NOTE: It's important that @credentials is initialized on
          #       intialization, because we need to capture the *current*
          #       credentials so that we can access the db to *update* to
          #       the new password.
          #
          def initialize(facade)
            @facade = facade
            @credentials = current_credentials
          end

          def db_uri
            url, uname, password = credential_resource_ids.map(&@credentials)
            "postgresql://#{uname}:#{password}@#{url}"
          end

          def username
            @credentials[username_id]
          end

          private

          def current_credentials
            @facade.current_values(credential_resource_ids)
          end

          def rotated_variable
            @facade.rotated_variable
          end

          def credential_resource_ids
            [url_id, username_id, password_id]
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

        class Database

          def initialize(credentials, pg)
            @credentials = credentials
            @pg = pg
          end

          def update_password(new_pw)
            username = @credentials.username
            conn = connection
            conn.exec("ALTER ROLE #{username} WITH PASSWORD '#{new_pw}'")
            conn.close
          end

          private

          def connection
            connection = @pg.connect(@credentials.db_uri)
            connection.exec('SELECT 1')
            connection
          end
        end

      end

    end
  end
end
