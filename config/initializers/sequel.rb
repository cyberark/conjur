require "sequel_rails/railties/legacy_model_config"

Sequel.extension :core_extensions

Sequel::Model.db ||= Sequel.connect(ENV['DATABASE_URL'])

if Rails.env == "development"
  Sequel::Model.db.loggers << Logger.new($stdout)
end
