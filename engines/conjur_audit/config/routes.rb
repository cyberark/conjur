# frozen_string_literal: true

ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"

api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
ENV['CONJUR_AUTHN_API_KEY'] = ENV[api_string]

ConjurAudit::Engine.routes.draw do
  scope format: false do
    root 'messages#index'
    get '/resources/:resource' => 'messages#index', constraints: {
      resource: %r{[^/?]+}
    }
    get '/roles/:role' => 'messages#index', constraints: {
      role: %r{[^/?]+}
    }
    get '/entities/:entity' => 'messages#index', constraints: {
      entity: %r{[^/?]+}
    }
  end
end
