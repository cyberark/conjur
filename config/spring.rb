if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start
end

Spring.after_fork do
  # Re-establish DB connections each time
  Sequel::Model.db.disconnect
end
