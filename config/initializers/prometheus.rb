
module Prometheus
  module Controller
    prometheus = Prometheus::Client.registry

    gauge = Prometheus::Client::Gauge.new(:test, docstring: 'Test gauge', labels: [:name, :env, :description])
    prometheus.register(gauge)
  end
end
