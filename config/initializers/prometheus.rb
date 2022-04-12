  # If using Prometheus telemetry, we want to ensure that the middleware
  # which collects and exports metrics is loaded at the start of the 
  # middleware chain to prevent any modifications to the incoming requests
  if Rails.application.config.conjur_config.telemetry_enabled 
    Monitoring::Prometheus.setup
    Rails.application.config.middleware.insert_before(0, Monitoring::Middleware::PrometheusExporter, registry: Monitoring::Prometheus.registry, path: '/metrics')
  end