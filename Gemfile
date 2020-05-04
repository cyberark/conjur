# frozen_string_literal: true

source 'https://rubygems.org'

# make sure to use tls for github
git_source(:github) { |name| "https://github.com/#{name}.git" }

ruby '~> 2.5.1'
#ruby-gemset=conjur

gem 'command_class'
gem 'base58'
gem 'http', '~> 4.2.0'
gem 'iso8601'
gem 'jbuilder', '~> 2.7.0'
gem 'nokogiri', '>= 1.8.2'
gem 'puma', '~> 3.12.5'
gem 'rack', '~> 2.0'
gem 'rails', '~> 5.2'
gem 'rake'
# gem 'sprockets', '~> 3.7.0', '>= 3.7.2'

gem 'pg'
# TODO: When updating to 5, sequel-rails was throwing errors that
# I wasn't able to resolve.  The quick fix was to pin sequel here
# for now.  We can tackle the upgrade later.
gem 'sequel', '4.49.0'
gem 'sequel-pg_advisory_locking'
gem 'sequel-postgres-schemata', require: false
gem 'sequel-rails'

gem 'activesupport'
gem 'base32-crockford'
gem 'bcrypt', '~> 3.1.2'
gem 'gli', require: false
gem 'listen'
#gem 'slosilo', '~> 2.1'
gem 'slosilo', github: 'cyberark/slosilo', branch: 'sha256'

# Explicitly required as there are vulnerabilities in older versions
gem "ffi", ">= 1.9.24"
gem "loofah", ">= 2.2.3"

# Installing ruby_dep 1.4.0
# Gem::InstallError: ruby_dep requires Ruby version >= 2.2.5, ~> 2.2.
gem 'ruby_dep', '= 1.3.1'

 # Pinned to update for role member search, using ref so merging and removing
# the branch doesn't immediately break this link
gem 'conjur-api', github: 'cyberark/conjur-api-ruby', branch: 'master'
gem 'conjur-policy-parser', '>= 3.0.4',
  github: 'cyberark/conjur-policy-parser', branch: 'master'
gem 'conjur-rack', '~> 4'
gem 'conjur-rack-heartbeat'
gem 'rack-rewrite'

# Putting this here currently confuses debify, so instead load it in
# application.rb gem 'conjur_audit', path: 'engines/conjur_audit'

# This old version is required to work with CC
# See: https://github.com/codeclimate/test-reporter/issues/418
gem 'simplecov', '0.14.1', require: false

# gem 'autoprefixer-rails'
# gem 'bootstrap-sass', '~> 3.4.0'
gem 'dry-struct', '~> 0.4.0'
gem 'dry-types', '~> 0.12.2'
# gem 'font-awesome-sass', '~> 4.7.0'
gem 'mini_racer'
gem 'net-ldap'
# gem 'sass-rails'
gem 'uglifier'

# for AWS rotator
gem 'aws-sdk-iam', require: false

group :production do
  gem 'rails_12factor'
end

# authn-k8s
gem 'kubeclient'
gem 'websocket-client-simple'

# authn-oidc
gem 'jwt'
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
  gem 'net-ssh'
  gem 'parallel'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'debase'
  gem 'rails-controller-testing'
  gem 'rails_layout'
  gem 'rake_shared_context'
  gem 'rspec'
  gem 'rspec-core', '~> 3.0'
  gem 'rspec-rails'
  gem 'ruby-debug-ide'
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
