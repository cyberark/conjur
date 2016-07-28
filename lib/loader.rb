require 'sequel'
require 'logger'

DB = Sequel::Model.db = Sequel.connect(ENV['DATABASE_URL'])

Sequel::Model.raise_on_save_failure = true

class Loader
  class << self
    def enable_logging
      DB.loggers << Logger.new($stdout)
    end
    
    def load account, filename
      start_t = Time.now
      DB.transaction do
        admin_id = "#{account}:user:admin"
        
        DB[:roles].delete

        $stderr.puts "Creating 'admin' user"
        admin = ::Role.create(role_id: admin_id)
        if admin_password = ENV['POSSUM_ADMIN_PASSWORD']
          $stderr.puts "Setting 'admin' password"
          admin_credentials = Credentials[role: admin] || Credentials.create(role: admin)
          admin_credentials.password = admin_password
          admin_credentials.save
        end
        
        records = Conjur::Policy::YAML::Loader.load_file(filename)
        $stderr.puts "Loading #{records.count} records from policy #{filename}"
        records = Conjur::Policy::Resolver.resolve records, account, "#{account}:user:admin"
        records.map(&:create!)
      end
      end_t = Time.now
      $stderr.puts "Loaded policy in #{end_t - start_t} seconds"
    end
  end
end
