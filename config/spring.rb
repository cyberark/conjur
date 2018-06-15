if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  load File.expand_path '../.simplecov', __dir__
end

Spring.after_fork do
  # Re-establish DB connections each time
  Sequel::Model.db.disconnect
end
