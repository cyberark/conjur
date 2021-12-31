require 'opentelemetry'
require 'opentelemetry/exporter/jaeger'
require 'opentelemetry/propagator/jaeger'
require 'opentelemetry/sdk'

OpenTelemetry::SDK.configure do |c|
  c.use_all()
end