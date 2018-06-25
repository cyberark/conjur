source 'https://rubygems.org'

# make sure to use tls for github
git_source(:github) { |name| "https://github.com/#{name}.git" }

#ruby=ruby-2.5.1
#ruby-gemset=conjur

gem 'rake'
gem 'sprockets', '~> 3.7.0', '>= 3.7.2'
gem 'rails-api'
gem 'rails', '~> 4.2'
gem 'nokogiri', '>= 1.8.2'
gem 'puma'
gem 'iso8601'
gem 'base58'
gem 'aws-sdk'

gem 'sequel-rails'
gem 'pg'
gem 'sequel-postgres-schemata', require: false

gem 'base32-crockford'
gem 'activesupport'
gem 'bcrypt-ruby', '~> 3.0.0'
gem 'random_password_generator', '= 1.0.0'
gem 'slosilo', '~> 2.1'
gem 'listen'
gem 'gli', require: false

# Installing ruby_dep 1.4.0
# Gem::InstallError: ruby_dep requires Ruby version >= 2.2.5, ~> 2.2.
gem 'ruby_dep', '= 1.3.1'

 # Pinned to update for role member search, using ref so merging and removing the branch doesn't
 # immediately break this link
gem 'conjur-api', github: 'cyberark/conjur-api-ruby', branch: 'master'
gem 'conjur-rack', '~> 3.1'
gem 'conjur-rack-heartbeat'
gem 'conjur-policy-parser', github: 'conjurinc/conjur-policy-parser', branch: 'possum'
gem 'rack-rewrite'

# Putting this here currently confuses debify, so instead load it in application.rb
# gem 'conjur_audit', path: 'engines/conjur_audit'

gem 'simplecov', require: false

gem 'sass-rails'
gem 'uglifier'
gem 'therubyracer'
#gem 'coffee-rails'
gem 'bootstrap-sass', '~> 3.2.0'
gem 'autoprefixer-rails'
gem 'font-awesome-sass', '~> 4.7.0'
gem 'net-ldap'
gem 'dry-struct'

group :production do
  gem 'rails_12factor'
end

group :development, :test do
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'conjur-debify', require: false
  gem 'spring'
  gem 'spring-commands-cucumber'
  gem 'spring-commands-rspec'
  gem 'json_spec'
  gem 'rspec'
  gem 'table_print'
  gem 'rspec-rails'
  gem 'ci_reporter_rspec'
  gem 'database_cleaner'
  gem 'parallel'
  gem 'cucumber'
  gem 'aruba'
  gem 'rake_shared_context'
  gem 'conjur-cli', '~> 6.1'
  gem 'rails_layout'
  gem 'rspec-core', '~> 3.0'
end

group :test do
  gem 'haikunator', '~> 1' # for generating random names in tests
end
