ENV['CONJUR_ACCOUNT'] = 'cucumber'
ENV['CONJUR_APPLIANCE_URL'] = 'http://localhost:3000'
  
require ::File.expand_path('../../../config/environment', __FILE__)

if ENV['DEBUG']
  Sequel::Model.db.loggers << Logger.new($stdout)
end

require 'conjur/api'
require 'conjur/cli'
require 'conjur/authn'

admin = Role["cucumber:user:admin"] || Role.create(role_id: "cucumber:user:admin")
unless admin.credentials
  Credentials.create role: admin
  admin.reload
end
  
Conjur::Config.load
Conjur::Config.apply
$admin_api = Conjur::API.new_from_key 'admin', admin.credentials.api_key
