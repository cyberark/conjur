require 'pg'

module Rotation
  module Rotators
    module Postgres

      class PasswordRotator

        #TODO better name
        #
        CurrentValues = Struct.new(:url, :username, :password)

        PrefixNotPresent = ::Util::ErrorClass.new("'{0}' has no prefix")
        MissingVariables = ::Util::ErrorClass.new(
          "The following variables are required: '{0}'"
        )

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
          new_pw = new_password
          pw_update = [resource_id, new_pw].to_h

          facade.update_variables(pw_update) do
            update_password_in_db(new_pw)
          end
        end

        private

        # TODO: move to RotatedVariable?
        #
        # def validate!(resource)
        #   raise PrefixNotPresent, resource.id unless resource.prefix
        # end
        def resource_id
          @facade.rotated_variable.resource_id
        end

        def update_password_in_db(new_pw)
          conn = db_connection
          conn.prepare('update_pw', "ALTER ROLE $1 WITH PASSWORD '$2'")
          conn.exec_prepared('update_pw', [current.username, new_pw])
          conn.close
        end

        # will raise an error on bad connection
        # TODO: wrap in domain specific error
        #
        def db_connection
          connection = @pg.connect(db_uri)
          connection.exec('SELECT 1')
          connection
        end

        def db_uri
          "postgresql://#{current.username}:#{current.password}@#{current.url}"
        end

        # Variables containing database connection info are expected to exist
        # TODO: Throw proper error if they don't
        #
        def current
          return @cur_values if @cur_values

          # These 3 are resource ids
          url      = "#{@password.prefix}/url"
          username = "#{@password.prefix}/username"
          pw       = @password.id

          vals = @conjur.current_values([url, username, pw])
          @cur_values = CurrentValues.new(vals[url], vals[username], vals[pw])
        end

        def new_password
          @password_factory.new(length: 20)
        end
      end

    end
  end
end
