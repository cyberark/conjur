Rails.application.routes.draw do
  scope format: false do
    get  '/authn/users' => 'authn_users#show'
    get  '/authn/users/login' => 'authn_users#login'
    put '/authn/users/password' => 'authn_users#update_password'
    put '/authn/users/api_key'  => 'authn_users#rotate_api_key'

    constraints id: /[^\/\?]+/ do
      post '/authn/users/:id/authenticate' => 'authenticate#authenticate'
    end
  end
end
