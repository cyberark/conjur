# require 'prometheus/client'
# require "prometheus/client/data_stores/direct_file_store"

# app_path = File.expand_path("../..", __dir__)

# # Unlink old Prometheus client store
# Dir["#{app_path}/tmp/prometheus/*.bin"].each do |file_path|
#   File.unlink(file_path)
# end

# # Relink client store
# puts "Initializing prometheus client store"
# Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: "#{app_path}/tmp/prometheus/")

# # Create a default Prometheus registry for our metrics.
# puts "Creating prometheus registry"
# prometheus = Prometheus::Client.registry

# # Create your metrics.
# TEST_GAUGE = Prometheus::Client::Gauge.new(:test_metric, docstring:'A metric for testing the Prometheus registery initialization.', labels:[:name])

# # Register your metrics with the registry we previously created.
# prometheus.register(TEST_GAUGE);
