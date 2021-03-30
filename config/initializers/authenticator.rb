# frozen_string_literal: true

require 'slosilo'
require 'slosilo/adapters/sequel_adapter'

require 'sequel'
require 'patches/core_ext'

Sequel.extension(:migration)

if %w[test development cucumber].member?(Rails.env)
  ENV['CONJUR_DATA_KEY'] ||= '4pSuk1rAQyuHA5uUYaj0X0BsiPCFb9Nc8J03XA6V5/Y='
end

if data_key = ENV['CONJUR_DATA_KEY']
  Slosilo::encryption_key = Base64.strict_decode64(data_key.strip)
  Slosilo::adapter = Slosilo::Adapters::SequelAdapter.new
else
  raise "No CONJUR_DATA_KEY"
end
