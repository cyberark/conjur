AuthnLdap::Engine.routes.draw do
  constraints id: %r{[^\/\?]+} do
    post '/authn/:account/:id/authenticate' => 'authenticate#authenticate'
  end
end
