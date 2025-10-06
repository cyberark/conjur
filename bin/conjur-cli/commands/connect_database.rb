# frozen_string_literal: true

require 'command_class'
require 'sequel'

module Commands
  ConnectDatabase = CommandClass.new(
    dependencies: {
      database_url: -> { ENV['DATABASE_URL'] } # runtime for testing purposes
    },

    inputs: %i[]
  ) do
    def call
      @database_url = @database_url.call if @database_url.respond_to?(:call)
      raise("DATABASE_URL not set") unless @database_url

      # already connected? Do not create new connection then
      return true if existing_connection?

      db_connection = nil
      30.times do
        db_connection = connect_db
        break unless db_connection.nil?

        $stderr.write('.')
        sleep(1)
      end

      raise("Database is still unavailable. Aborting!") if db_connection.nil?

      Sequel::Model.db = db_connection

      true
    end

    private

    def connect_db
      db = Sequel.connect(@database_url)
      db['select 1'].first
      db
    rescue
      db&.disconnect
      nil
    end

    def existing_connection?
      Sequel::Model.db
      true
    rescue Sequel::Error
      false
    end
  end
end
