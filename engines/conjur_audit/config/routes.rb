# frozen_string_literal: true

parallel_cuke_vars = Hash.new
parallel_cuke_vars['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
parallel_cuke_vars['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
parallel_cuke_vars['CONJUR_AUTHN_API_KEY'] = ENV["CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"]

parallel_cuke_vars.each do |key, value|
  if ENV[key].nil? || ENV[key].empty?
    ENV[key] = value
  end
end

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
