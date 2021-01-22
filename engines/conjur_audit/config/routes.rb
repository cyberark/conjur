# frozen_string_literal: true

ConjurAudit::Engine.routes.draw do
  scope format: false do
    root 'messages#index'
    get '/resources/:resource' => 'messages#index', constraints: {
      resource: %r{[^\/\?]+}
    }
    get '/roles/:role' => 'messages#index', constraints: {
      role: %r{[^\/\?]+}
    }
    get '/entities/:entity' => 'messages#index', constraints: {
      entity: %r{[^\/\?]+}
    }
  end
end
