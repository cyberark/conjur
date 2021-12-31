require 'opentelemetry'
require 'opentelemetry/common'
require 'opentelemetry/exporter/jaeger'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/base'
require 'opentelemetry/instrumentation/pg'
require 'opentelemetry/instrumentation/http'
require 'opentelemetry/instrumentation/http_client'
require 'opentelemetry/instrumentation/rack'
require 'opentelemetry/instrumentation/rails'
require 'opentelemetry/instrumentation/rspec'
require 'opentelemetry/instrumentation/sinatra'
require 'opentelemetry/propagator/jaeger'
require 'opentelemetry/sdk'
OpenTelemetry::SDK.configure do |c|
  c.id_generator = OpenTelemetry::Propagator::Jaeger::IDGenerator
  c.service_name = 'Conjur'
  c.use_all()
end
