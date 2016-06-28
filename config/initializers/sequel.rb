require "sequel_rails/railties/legacy_model_config"

Sequel.extension :core_extensions
Sequel::Model.db.extension :pg_array, :pg_inet
