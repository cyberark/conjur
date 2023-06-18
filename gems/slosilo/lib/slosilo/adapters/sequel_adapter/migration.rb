require 'sequel'

module Slosilo
  module Adapters::SequelAdapter::Migration
    # The default name of the table to hold the keys
    DEFAULT_KEYSTORE_TABLE = :slosilo_keystore

    # Sets up default keystore table name
    def self.extended(db)
      db.keystore_table ||= DEFAULT_KEYSTORE_TABLE
    end
    
    # Keystore table name. If changing this do it immediately after loading the extension.
    attr_accessor :keystore_table

    # Create the table for holding keys
    def create_keystore_table
      # docs say to not use create_table? in migration;
      # but we really want this to be robust in case there are any previous installs
      # and we can't use table_exists? because it rolls back
      create_table? keystore_table do
        String :id, primary_key: true
        bytea :key, null: false
        String :fingerprint, unique: true, null: false
      end
    end
    
    # Drop the table
    def drop_keystore_table
      drop_table keystore_table
    end
  end
  
  module Extension
    def slosilo_keystore
      extend Slosilo::Adapters::SequelAdapter::Migration
    end
  end
  
  Sequel::Database.send :include, Extension
end

Sequel.migration do
  up do
    slosilo_keystore
    create_keystore_table
  end
  down do
    slosilo_keystore
    drop_keystore_table
  end
end
