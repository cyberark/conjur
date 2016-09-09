require 'sequel'
require 'logger'

DB = Sequel::Model.db = Sequel.connect(ENV['DATABASE_URL'])

Sequel::Model.raise_on_save_failure = true

class BootstrapLoader
  class << self
    def enable_logging
      DB.loggers << Logger.new($stdout)
    end
    
    def load account, filename
      start_t = Time.now
      DB.transaction do
        admin_id = "#{account}:user:admin"
        admin = ::Role[admin_id] || ::Role.create(role_id: admin_id)
        if admin_password = ENV['POSSUM_ADMIN_PASSWORD']
          $stderr.puts "Setting 'admin' password"
          admin_credentials = Credentials[role: admin] || Credentials.create(role: admin)
          admin_credentials.password = admin_password
          admin_credentials.save
        end

        bootstrap_policy_resource = Loader::Types.find_or_create_bootstrap_policy(account)

        policy_version = PolicyVersion.new role: admin, policy: bootstrap_policy_resource, policy_text: File.read(filename)
        policy_version.save
        loader = Loader::Orchestrate.new policy_version
        loader.load
      end
      end_t = Time.now
      $stderr.puts "Loaded policy in #{end_t - start_t} seconds"
    end
  end
end
