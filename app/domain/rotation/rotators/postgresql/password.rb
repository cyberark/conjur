require 'pg'

module Rotation
  module Rotators
    module Postgresql

      class Password

        # TODO: add these back in
        #
        # PrefixNotPresent = ::Util::ErrorClass.new("'{0}' has no prefix")
        # MissingVariables = ::Util::ErrorClass.new(
        #   "The following variables are required: '{0}'"
        # )

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
          new_pw      = db.new_password
          pw_update   = Hash[resource_id, new_pw]

          facade.update_variables(pw_update) do
            p "Connect to db and update: #{pw_update}"
            p db.db_uri
            #
            # TODO uncomment for real action
            # db.update_password(new_pw)
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
          end

          def new_password
            len = policy_vals[pw_length_id] || 20
            @password_factory.new(length: len)
          end

          def update_password(new_pw)
            conn = connection
            conn.prepare('update_pw', "ALTER ROLE $1 WITH PASSWORD '$2'")
            conn.exec_prepared('update_pw', [current.username, new_pw])
            conn.close
          end

          # will raise an error on bad connection
          # TODO: wrap in domain specific error
          #
          def connection
            connection = @pg.connect(db_uri)
            connection.exec('SELECT 1')
            connection
          end

          def db_uri
            url, username, password = credential_ids.map { |x| policy_vals[x] }
            "postgresql://#{username}:#{password}@#{url}"
          end

          private

          # Values of the postgres rotator related variables in policy.yml
          #
          def policy_vals
            @policy_vals ||= @facade.current_values(
              credential_ids << pw_length_id
            )
          end

          # Variables containing database connection info are expected to exist
          # TODO: Throw proper error if they don't
          #
          def credential_ids
            @credential_ids ||= [url_id, username_id, password_id]
          end

          def rotated_variable
            @facade.rotated_variable
          end

          def pw_length_id
            rotated_variable.sibling_id('password/length')
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
