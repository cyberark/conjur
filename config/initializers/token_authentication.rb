# frozen_string_literal: true

require 'rack/token_authentication'

Rails.application.configure do
  # Defines the routes which do not require an auth token (`except`) and the
  # routes which may utilize an auth token (`optional`).
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
