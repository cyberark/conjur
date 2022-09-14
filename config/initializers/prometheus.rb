require 'monitoring/pub_sub'

if Rails.application.config.conjur_config.telemetry_enabled 
  require 'monitoring/prometheus'
  require 'monitoring/metrics'
  # Require all defined metrics
  Dir.glob(Rails.root + 'lib/monitoring/metrics/*.rb', &method(:require))

  # Load the authentication module early so that telemetry can see which authenticators are installed on startup
  Dir.glob(Rails.root + 'app/domain/authentication/**/*.rb', &method(:require))

  # Register new metrics and setup the Prometheus client store
  metrics = [
    Monitoring::Metrics::ApiRequestCounter.new,
    Monitoring::Metrics::ApiRequestHistogram.new,
    Monitoring::Metrics::ApiExceptionCounter.new,
    Monitoring::Metrics::PolicyResourceGauge.new,
    Monitoring::Metrics::PolicyRoleGauge.new,
    Monitoring::Metrics::AuthenticatorGauge.new,
  ]
  Monitoring::Prometheus.setup(metrics: metrics)

  # Initialize Prometheus middleware. We want to ensure that the middleware
  # which collects and exports metrics is loaded at the start of the 
  # middleware chain to prevent any modifications to incoming HTTP requests
  Rails.application.config.middleware.insert_before(0, Monitoring::Middleware::PrometheusExporter, registry: Monitoring::Prometheus.registry, path: '/metrics')
  Rails.application.config.middleware.insert_before(0, Monitoring::Middleware::PrometheusCollector, pubsub: Monitoring::PubSub.instance)
end
