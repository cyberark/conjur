require 'pg'

module Rotation
  module Rotators
    module Postgres

      class PasswordRotator

        CurrentValues = Struct.new(:url, :username, :password)

        PrefixNotPresent = ::Util::ErrorClass.new("'{0}' has no prefix")
        MissingVariables = ::Util::ErrorClass.new(
          "The following variables are required: '{0}'"
        )

        # Password is instance of MasterRotator::Resource object (reification
        # of resource_id) 
        #
        def initialize(
          password:,
          conjur_facade: ::Rotation::ConjurFacadeForRotators,
          password_factory: Base58Password,
          pg: PG
        )
          @password = password
          @conjur = conjur_facade
          @password_factory = password_factory
          @pg = pg
          validate!
        end

        # TODO:
        #
        # Or maybe it could be done as (1) @pg.connect (2) start transaction (3)
        # set new password (4) update password in conjur (5) commit transaction
        # (6) close connection
        def rotate
          new_pw = new_password
          update_password_in_db(new_pw)
          update_password_in_conjur(new_pw)
        end

        private

        def validate!(resource)
          raise PrefixNotPresent, resource.id unless resource.prefix
        end

        def update_password_in_conjur(new_pw)
          @conjur.update_variables({@password.id => new_pw})
        end

        def update_password_in_db(new_pw)
          conn = db_connection
          conn.prepare('update_pw', "ALTER ROLE $1 WITH PASSWORD '$2'")
          conn.exec_prepared('update_pw', [current.username, new_pw])
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
