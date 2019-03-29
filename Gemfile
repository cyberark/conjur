# frozen_string_literal: true

source 'https://rubygems.org'

# make sure to use tls for github
git_source(:github) { |name| "https://github.com/#{name}.git" }

#ruby=ruby-2.5.1
#ruby-gemset=conjur

gem 'command_class'
gem 'base58'
gem 'iso8601'
gem 'nokogiri', '>= 1.8.2'
gem 'puma', ' ~> 3.10'
gem 'rack', '~> 1.6.11'
gem 'rails', '= 4.2.11'
gem 'rails-api'
gem 'rake'
gem 'sprockets', '~> 3.7.0', '>= 3.7.2'

gem 'pg'
gem 'sequel-postgres-schemata', require: false
gem 'sequel-rails'

gem 'activesupport'
gem 'base32-crockford'
gem 'bcrypt-ruby', '~> 3.0.0'
gem 'gli', require: false
gem 'listen'
gem 'random_password_generator', '= 1.0.0'
gem 'slosilo', '~> 2.1'

# Explicitly required as there are vulnerabilities in older versions
gem "ffi", ">= 1.9.24"
gem "loofah", ">= 2.2.3"

# Installing ruby_dep 1.4.0
# Gem::InstallError: ruby_dep requires Ruby version >= 2.2.5, ~> 2.2.
gem 'ruby_dep', '= 1.3.1'

 # Pinned to update for role member search, using ref so merging and removing the branch doesn't
 # immediately break this link
gem 'conjur-api', github: 'cyberark/conjur-api-ruby', branch: 'master'
gem 'conjur-policy-parser', '>= 3.0.3',
  github: 'conjurinc/conjur-policy-parser', branch: 'possum'
gem 'conjur-rack', '~> 3.1'
gem 'conjur-rack-heartbeat'
gem 'rack-rewrite'

# Putting this here currently confuses debify, so instead load it in application.rb
# gem 'conjur_audit', path: 'engines/conjur_audit'

gem 'simplecov', require: false

gem 'sass-rails'
gem 'therubyracer'
gem 'uglifier'
#gem 'coffee-rails'
gem 'autoprefixer-rails'
gem 'bootstrap-sass', '~> 3.2.0'
gem 'dry-struct'
gem 'font-awesome-sass', '~> 4.7.0'
gem 'net-ldap'
gem 'net-ssh'

# for AWS rotator
gem 'aws-sdk-iam', require: false

group :production do
  gem 'rails_12factor'
end

# authn-k8s
gem 'kubeclient'
gem 'websocket-client-simple'

# authn-oidc
gem 'openid_connect'

group :development, :test do
  gem 'aruba'
  gem 'csr'
  gem 'ci_reporter_rspec'
  gem 'conjur-cli', '~> 6.1'
  gem 'conjur-debify', require: false
  gem 'cucumber'
  gem 'database_cleaner'
  gem 'json_spec'
  gem 'parallel'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'ruby-debug-ide'
  gem 'debase'
  gem 'rails_layout'
  gem 'rake_shared_context'
  gem 'rspec'
  gem 'rspec-core', '~> 3.0'
  gem 'rspec-rails'
  gem 'spring'
  gem 'spring-commands-cucumber'
  gem 'spring-commands-rspec'
  gem 'table_print'
end

group :development do
  # note: minor version of this needs to match codeclimate channel
  gem 'rubocop', '~> 0.58.0', require: false

  gem 'reek', require: false
  gem 'rubocop-checkstyle_formatter', require: false # for Jenkins
end

group :test do
  gem 'haikunator', '~> 1' # for generating random names in tests
end
