if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start do
    coverage_dir File.join(ENV['REPORT_ROOT'], 'coverage')
  end
end

Spring.after_fork do
  # Re-establish DB connections each time
  Sequel::Model.db.disconnect
end
