require 'slosilo'
require 'slosilo/adapters/sequel_adapter'

require 'sequel'
require 'conjur/core_ext'

Sequel.extension :migration

if %w(test cucumber).member?(Rails.env)
  ENV['POSSUM_SLOSILO_KEY'] ||= '4pSuk1rAQyuHA5uUYaj0X0BsiPCFb9Nc8J03XA6V5/Y='
end

Slosilo::encryption_key = ENV['POSSUM_SLOSILO_KEY'].decode64 if ENV['POSSUM_SLOSILO_KEY']
Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new

# Token authentication is optional for all routes
Possum::Application.config.middleware.use Conjur::Rack::Authenticator, optional: [ /.*/ ], except: [ /^\/users\/.*\/authenticate$/ ]
