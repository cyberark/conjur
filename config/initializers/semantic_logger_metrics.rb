# Hash of metrics we're tracking in Conjur.
metrics = {
  'Policy/load_policy': ::Prometheus::Client::Histogram.new(
    :conjur_policy_load_duration,
    docstring: 'Time to load a policy',
    labels: %i[name metric]
  )
}

# Registers each metric so it can be utilized by Prometheus
registry = ::Prometheus::Client.registry
metrics.each do |_, metric|
  registry.register(metric)
end

prometheus_subscriber = Monitoring::Metrics::Prometheus::Subscriber.new(
  {}.tap do |hsh|
    metrics.each do |key, metric|
      hsh[key] = Monitoring::Metrics::Prometheus::GenericMetric.new(metric: metric)
    end
  end
)
SemanticLogger.on_log(prometheus_subscriber)
