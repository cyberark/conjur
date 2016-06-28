require 'sequel_rails/storage'
require 'byebug'

module DatabasePreparer
  FRESH_DB_NAME =  'authn-fresh'
  
  def self.connect cnf
    if cnf['url']
      db = Sequel::connect cnf['url'], cnf
    else
      db = Sequel::connect cnf
    end
  end

  def self.create config, name
    db = connect config
    db.execute "DROP DATABASE IF EXISTS " + db.quote_identifier(name)
    db.execute "CREATE DATABASE " + db.quote_identifier(name)
    db.disconnect
  end

  def self.drop config, name
    db = connect config
    db.execute "DROP DATABASE IF EXISTS " + db.quote_identifier(name)
    db.disconnect
  end

  def with_fresh_database &block
    base_config = Rails.application.config.sequel.environments['test']
    db_config = base_config.merge('database' => FRESH_DB_NAME)
    if db_config['url']
      uri = URI.parse(db_config['url'])
      uri.path = '/' + FRESH_DB_NAME
      db_config.merge! 'url' => uri.to_s
    end
    db = DatabasePreparer.connect db_config
    let(:db) { db }
    
    before(:all) do
      DatabasePreparer::create base_config, FRESH_DB_NAME
      unq_db = DatabasePreparer::connect db_config.except('search_path')
      unq_db.instance_eval &block
      unq_db.disconnect
      @old_db = Sequel::Model.db
      Sequel::Model.db = db
    end
    
    after(:all) do
      Sequel::Model.db.disconnect
      Sequel::Model.db = @old_db
      DatabasePreparer::drop base_config, FRESH_DB_NAME
    end
  end
end

RSpec::Core::ExampleGroup.send :extend, DatabasePreparer
