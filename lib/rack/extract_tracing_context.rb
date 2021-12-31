# frozen_string_literal: true

require 'forwardable'
require 'bundler/setup'
require 'opentelemetry/sdk'
require 'opentelemetry/common'

module Rack
    # Rack OpenTelemtry middleware to extract trace span context, create child span, and add
    # attributes/events to the span
    class ExtractTracingContext
        def initialize(app)
            @app = app
            @tracer = OpenTelemetry.tracer_provider.tracer('propagation', '1.0')
        end
    
        def call(env)
            if env["HTTP_TRACEPARENT"]
                # Extract context from request headers
                propagator = OpenTelemetry::Trace::Propagation::TraceContext.text_map_propagator
                OpenTelemetry.propagation = propagator
                context = OpenTelemetry.propagation.extract(
                    env,
                    getter: OpenTelemetry::Common::Propagation.rack_env_getter
                )
            
                span_name = "Context Propagation"
            
                # Activate the extracted context
                OpenTelemetry::Context.with_current(context) do
                    # Span kind MUST be `:server` for a HTTP server span
                    @tracer.in_span(
                    span_name,
                    attributes: {
                        'component' => 'http',
                    },
                    kind: :server
                    ) do |span|
                        @app.call(env)
                    end
                end
            else
                @app.call(env)
            end
        end
    end
end