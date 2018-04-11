require 'slosilo'
require 'slosilo/adapters/sequel_adapter'

require 'sequel'
require 'patches/core_ext'

Sequel.extension :migration

# Token authentication is optional for authn routes, and it's not applied at all to authentication.
Possum::Application.config.middleware.use Conjur::Rack::Authenticator,
  optional: [
    /^\/authn-[^\/]+\//,
    /^\/authn\//,
    /^\/public_keys\//
  ],
  except: [
    /^\/authn-[^\/]+\/.*\/authenticate$/,
    /^\/authn\/.*\/authenticate$/,
    /^\/host_factories\/hosts$/,
    /^\/assets\/.*/,
    /^\/$/
  ]

if %w(test development cucumber).member?(Rails.env)
  ENV['CONJUR_DATA_KEY'] ||= '4pSuk1rAQyuHA5uUYaj0X0BsiPCFb9Nc8J03XA6V5/Y='
end

if data_key = ENV['CONJUR_DATA_KEY']
  Slosilo::encryption_key = Base64.strict_decode64 data_key.strip
  Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new
else
  raise "No CONJUR_DATA_KEY"
end
