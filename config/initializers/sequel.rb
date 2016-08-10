Sequel.extension :core_extensions

Sequel::Model.db.sql_log_level = :debug
Sequel::Model.db.loggers << Rails.logger
