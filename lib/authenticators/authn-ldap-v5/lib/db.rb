# require 'slosilo'
# require 'sequel'

# DB = Sequel.connect ENV['DATABASE_URL'] || 'postgres:/', search_path: 'authn'
# require 'slosilo/adapters/sequel_adapter'
# Slosilo::encryption_key ||= Base64.decode64(ENV['AUTHN_SLOSILO_KEY']) if ENV['AUTHN_SLOSILO_KEY']
# Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new
