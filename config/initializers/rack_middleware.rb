require 'rack/default_content_type'

# This is where we introduce custom middleware that interacts with Rack
# and Rails to change how requests are handled.
Rails.application.configure do
  # This configures which paths do and do not require token authentication.
  # Token authentication is optional for authn routes, and it's not applied at
  # all to authentication, host factories, or static assets (e.g. images, CSS)
  config.middleware.use(Conjur::Rack::Authenticator,
                        optional: [
                          %r{^/authn-[^/]+/},
                          %r{^/authn/},
                          %r{^/public_keys/}
                        ],
                        except: [
                          %r{^/authn-oidc/.*/providers},
                          %r{^/authn-[^/]+/.*/authenticate$},
                          %r{^/authn/.*/authenticate$},
                          %r{^/host_factories/hosts$},
                          %r{^/assets/.*},
                          %r{^/authenticators$},
                          %r{^/$}
                        ])

  # We want to ensure requests have an expected content type
  # before other middleware runs to make sure any body parsing
  # attempts are handled correctly. So we add this middleware
  # to the start of the Rack middleware chain.
  config.middleware.insert_before(0, ::Rack::DefaultContentType)

  # If using Prometheus telemetry, we want to ensure that the middleware
  # which collects and exports metrics is loaded at the start of the 
  # middleware chain to prevent any modifications to the incoming requests
  config.middleware.insert_before(0, Monitoring::Middleware::PrometheusExporter, registry: Monitoring::Prometheus.registry, path: '/metrics')

  # Deleting the RemoteIp middleware means that `request.remote_ip` will
  # always be the same as `request.ip`. This ensure that the Conjur request log
  # (using `remote_ip`) and the audit log (using `ip`) will have the same value
  # for each request.
  config.middleware.delete(ActionDispatch::RemoteIp)
end
