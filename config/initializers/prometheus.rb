require 'monitoring/pub_sub'


Rails.application.configure do
  return unless config.conjur_config.telemetry_enabled

  require 'monitoring/prometheus'
  require 'monitoring/metrics'
  # Require all defined metrics
  Dir.glob(Rails.root + 'lib/monitoring/*.rb', &method(:require))
  Dir.glob(Rails.root + 'lib/monitoring/metrics/*.rb', &method(:require))

  registry = ::Prometheus::Client::Registry.new
  # Register new metrics and setup the Prometheus client store
  metrics = [
    Monitoring::Metrics::ApiRequestCounter.new,
    Monitoring::Metrics::ApiRequestHistogram.new,
    Monitoring::Metrics::ApiExceptionCounter.new,
    Monitoring::Metrics::PolicyResourceGauge.new,
    Monitoring::Metrics::PolicyRoleGauge.new,
    Monitoring::Metrics::AuthenticatorGauge.new,
  ]

  lazy_init = lambda do
    Monitoring::Prometheus.setup(metrics: metrics, registry: registry)
  end

  # Initialize Prometheus middleware. We want to ensure that the middleware
  # which collects and exports metrics is loaded at the start of the 
  # middleware chain to prevent any modifications to incoming HTTP requests
  Rails.application.config.middleware.insert_before(0, Monitoring::Middleware::PrometheusExporter, registry: registry, path: '/metrics')
  Rails.application.config.middleware.insert_before(0, Monitoring::Middleware::PrometheusCollector, pubsub: Monitoring::PubSub.instance, lazy_init: lazy_init)
end
