require 'sequel'
require 'logger'

DB = Sequel::Model.db = Sequel.connect(ENV['DATABASE_URL'])

Sequel::Model.raise_on_save_failure = true

class Loader
  class << self
    def enable_logging
      DB.loggers << Logger.new($stdout)
    end
    
    def load filename, account
      records = Conjur::Policy::YAML::Loader.load_file(filename)
      records = Conjur::Policy::Resolver.resolve records, account, "#{account}:user:admin"

      DB[:roles].delete

      ::Role.create id: "#{account}:user:admin"
      
      records.map(&:create!)
    end
  end
end
