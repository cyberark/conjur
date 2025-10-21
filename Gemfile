# frozen_string_literal: true

source 'https://rubygems.org'

# ruby=ruby-3.0
# ruby-gemset=conjur

plugin 'bundler-override'
require File.join(
  Bundler::Plugin.index.load_paths('bundler-override')[0],
  'bundler-override'
) rescue nil

# make sure to use tls for github
git_source(:github) { |name| "https://github.com/#{name}.git" }

# Do not use fuzzy version matching (~>) with the Ruby version. It doesn't play
# nicely with RVM and we should be explicit since Ruby is such a fundamental
# part of a Rails project. The Ruby version is also locked in place by the
# Docker base image so it won't be updated with fuzzy matching.
if Bundler::Plugin.installed?('bundler-override')
  override 'rails', drop: 'activestorage'
  override 'actionmailbox', drop: 'activestorage'
  override 'actiontext', drop: 'activestorage'
end

gem 'base58'
gem 'command_class'
gem 'concurrent-ruby', '!= 1.3.5'
gem 'http', '~> 4.2.0'
gem 'iso8601'
gem 'mustache'
gem 'net-imap', '>= 0.5.8'
gem 'nokogiri', '>= 1.18.9'
gem 'puma', '~> 6', '>= 6.4.3'
gem 'rack', '>= 2.2.20'
gem 'rails', '~> 7.2', '>= 7.2.2.2'
gem 'rake'

gem 'pg'
gem 'sequel'
gem 'sequel-pg_advisory_locking'
gem 'sequel-postgres-schemata', require: false
gem 'sequel-rails'

gem 'base32-crockford'
gem 'bcrypt'
gem 'gli', require: false
gem 'listen'
gem 'rexml', '~> 3.4.2'
gem 'slosilo', '~> 3.0'

# Explicitly required as there are vulnerabilities in older versions
gem "ffi", ">= 1.9.24"
gem "loofah", ">= 2.2.3"

# Pinned to update for role member search, using ref so merging and removing
# the branch doesn't immediately break this link
gem 'conjur-policy-parser', path: 'gems/policy-parser'
gem 'conjur-rack', path: 'gems/conjur-rack'
gem 'conjur-rack-heartbeat'
gem 'rack-rewrite'

# Putting this here currently confuses debify, so instead load it in
# application.rb gem 'conjur_audit', path: 'engines/conjur_audit'

gem 'dry-struct'
gem 'dry-types'
gem 'dry-validation'
gem 'net-ldap'

# for AWS rotator
gem 'aws-sdk-iam', require: false

# we need this version since any newer introduces braking change that causes issues with safe_yaml: https://github.com/ruby/psych/discussions/571
gem 'psych', '=3.3.2'

group :production do
  gem 'rails_12factor'
end

# authn-k8s
gem 'event_emitter'
gem 'kubeclient'
gem 'websocket'

# authn-oidc, gcp, azure, jwt
# gem 'jwt', '2.2.2' # version frozen due to authn-jwt requirements
gem 'jwt', '2.7.1'
# authn-oidc
gem 'openid_connect', '~> 2.0'

gem "anyway_config"
gem 'i18n', '~> 1.8.11'
gem 'json_schemer'
gem 'prometheus-client'

# sigdump allows the Conjur server processes to respond to the SIGCONT signal
# and produce a thread dump of the processes for support and debugging.
gem 'sigdump', require: 'sigdump/setup'

group :development, :test do
  gem 'aruba'
  gem 'ci_reporter_rspec'
  gem 'csr'
  gem 'cucumber', '~> 7.1'
  gem 'database_cleaner', '~> 1.8'
  gem 'debase', '~> 0.2.5.beta2'
  gem 'debase-ruby_core_source', '~> 3.3'
  gem 'debug' # For VSCode debugging
  gem 'faye-websocket'
  gem 'json_spec', '~> 1.1'
  gem 'net-ssh'
  gem 'parallel'
  gem 'parallel_tests'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rails-controller-testing'
  gem 'rails_layout'
  gem 'rake_shared_context'
  gem 'rspec'
  gem 'rspec-core'
  gem 'rspec-rails'

  # We use a post-coverage hook to sleep covered processes until we're ready to
  # collect the coverage reports in CI. Because of this, we don't want bundler
  # to auto-load simplecov. Rather we require it directly when we need it.
  gem 'simplecov', require: false

  gem 'spring'
  gem 'spring-commands-cucumber'
  gem 'spring-commands-rspec'
  gem 'table_print'
  gem 'vcr'
  gem 'webmock', '>= 3.19.0'
  gem 'webrick'
end

group :development do
  # NOTE: minor version of this needs to match codeclimate channel
  gem 'rubocop', '>= 1.57.0', require: false

  gem 'reek', require: false
  gem 'rubocop-checkstyle_formatter', '>= 0.5.0', require: false # for Jenkins
end

group :test do
  gem 'haikunator', '~> 1' # for generating random names in tests
end
