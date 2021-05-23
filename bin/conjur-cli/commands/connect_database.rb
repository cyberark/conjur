# frozen_string_literal: true

require 'command_class'
require 'sequel'

module Commands
  ConnectDatabase ||= CommandClass.new(
    dependencies: {
      database_url: ENV['DATABASE_URL']
    },

    inputs: %i[]
  ) do
    def call
      fail("DATABASE_URL not set") unless @database_url

      30.times do
        break if test_select
    
        $stderr.write('.')
        sleep(1)
      end

      raise "Database is still unavailable. Aborting!" unless test_select

      true
    end

    private

    def test_select
      db = Sequel::Model.db = Sequel.connect(@database_url)
      db['select 1'].first
    rescue
      false
    end
  end
end
