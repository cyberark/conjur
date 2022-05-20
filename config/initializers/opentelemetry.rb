if Rails.application.config.conjur_config.tracing_enabled
  require 'opentelemetry'
  require 'opentelemetry/exporter/jaeger'
  require 'opentelemetry/sdk'

  OpenTelemetry::SDK.configure do |c|
    c.use_all()
  end

  Rails.application.configure do
    #Use for Opentelemtry tracing
    config.tracer = OpenTelemetry.tracer_provider.tracer('my-tracer')
  end
end