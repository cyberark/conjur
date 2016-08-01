Possum::Application.config.middleware.insert_before Rails::Rack::Logger, Conjur::Rack::PathPrefix, '/api/v5'
