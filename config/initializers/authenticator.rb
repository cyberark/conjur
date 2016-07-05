require 'slosilo'
require 'slosilo/adapters/sequel_adapter'

require 'sequel'
require 'patches/core_ext'

Sequel.extension :migration

if %w(test development cucumber).member?(Rails.env)
  ENV['POSSUM_SLOSILO_KEY'] ||= '4pSuk1rAQyuHA5uUYaj0X0BsiPCFb9Nc8J03XA6V5/Y='
end

Slosilo::encryption_key = ENV['POSSUM_SLOSILO_KEY'].decode64 if ENV['POSSUM_SLOSILO_KEY']
Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new

# Token authentication is optional for all routes
Possum::Application.config.middleware.use Conjur::Rack::Authenticator, optional: [ /.*/ ], except: [ /^\/users\/.*\/authenticate$/ ]

own = begin
  Slosilo[:own]
rescue
  if $!.message =~ /PG::UndefinedTable/
    :none
  else
    raise
  end
end

if ENV['POSSUM_PRIVATE_KEY']
  key = Slosilo::Key.new(ENV['POSSUM_PRIVATE_KEY'])
  if :none == own
    # pass
  elsif own
    raise "Existing token-signing key does not match POSSUM_PRIVATE_KEY" unless Slosilo[:own] == key
  else
    own = Slosilo[:own] = key
  end
end

raise "Private token-signing key is not available" unless own
