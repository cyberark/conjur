# frozen_string_literal: true
require 'aws-sdk-rds'
require 'command_class'
require 'sequel'
require_relative '../../../config/initializers/sequel_connect'


module Commands
  ConnectDatabase ||= CommandClass.new(
    dependencies: {
      database_url: ENV['DATABASE_URL']
    },

    inputs: %i[]
  ) do
    def call
      status = false
      30.times do
        status = connect
        break if status
        $stderr.write('.')
        sleep(1)
      end

      raise "Database is still unavailable. Aborting!" unless status

      true
    end

    private

    def connect
      if ENV['RAILS_ENV'] == 'cloud'
        # when running on cloud, get the configuration from database.yml file
        config = get_db_config
        # Connect to the database using Sequel
        db = Sequel::Model.db =  Sequel.connect(config)
      else
        fail("DATABASE_URL not set") unless @database_url
        db = Sequel::Model.db = Sequel.connect(@database_url)
      end
      db['select 1'].first
      db.disconnect
      true
    rescue => e
      $stderr.puts(e.message)
      false
    end

    private

    def get_db_config
      # Load the database configuration from the YAML file
      yaml_content = File.read('config/database.yml')
      processed_content = ERB.new(yaml_content).result
      config = YAML.safe_load(processed_content)['cloud']

      # The list of mandatory fields
      mandatory_fields = %w(adapter database user password host)

      # Check if all mandatory fields are present
      missing_fields = mandatory_fields - config.keys
      unless missing_fields.empty?
        error = "Missing mandatory fields in database.yml: #{missing_fields.join(', ')}"
        raise error
      end
      config
    end
  end
end