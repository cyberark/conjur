# frozen_string_literal: true

Sequel.split_symbols = true
Sequel.extension(:core_extensions, :postgres_schemata)
Sequel::Model.plugin(:validation_helpers)

class Sequel::Model
  def write_id_to_json response, field
    value = response.delete("#{field}_id")
    response[field] = value if value
  end
end

Rails.application.configure do
  config.sequel.after_connect = proc do
    Sequel.extension(:core_extensions, :postgres_schemata)
    Sequel::Model.db.extension(:pg_array, :pg_inet)
  end

  # The default connection pool does not support closing connections.
  # We must be able to close connections on demand to clear the connection cache
  # after policy loads [cyberark/conjur#2584](https://github.com/cyberark/conjur/pull/2584)
  # The [ShardedThreadedConnectionPool](https://www.rubydoc.info/github/jeremyevans/sequel/Sequel/ShardedThreadedConnectionPool) does support closing connections on-demand.
  # Sequel is configured to use the ShardedThreadedConnectionPool by setting the servers configuration on
  # the database connection [docs](https://www.rubydoc.info/github/jeremyevans/sequel/Sequel%2FShardedThreadedConnectionPool:servers)
  config.sequel.servers = {}

  # Whether to dump the schema after successful migrations.
  # Defaults to false in production and test, true otherwise.
  config.sequel.schema_dump = false

  # Max Postgres connections should be no less than the number of threads
  # available to the web worker to avoid pool timeouts.
  begin
    threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 16)
  rescue ArgumentError
    raise(
      "Invalid value for RAILS_MAX_THREADS environment variable: " \
      "'#{ENV['RAILS_MAX_THREADS']}'. " \
      "Value must be a positive integer (default is 16)."
    )
  end

  begin
    connections_per_thread = Float(ENV['DATABASE_CONNECTIONS_PER_THREAD'] || 1.2)
  rescue ArgumentError
    raise(
      "Invalid value for DATABASE_CONNECTIONS_PER_THREAD environment variable: " \
      "'#{ENV['DATABASE_CONNECTIONS_PER_THREAD']}'. " \
      "Value must be a positive decimal (default is 1.2)."
    )
  end

  config.sequel.max_connections = (threads_count * connections_per_thread).ceil
end
