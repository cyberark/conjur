# frozen_string_literal: true

require 'rack/token_authentication'

Rails.application.configure do
  # This configures which paths do and do not require token authentication.
  # Token authentication is optional for authn routes, and it's not applied at
  # all to authentication, host factories, or static assets (e.g. images, CSS)
  config.middleware.use(Rack::TokenAuthentication, {
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
    ]
  })
end
