AuthnLdap::Engine.routes.draw do
  constraints id: %r{[^\/\?]+} do
    post '/authn/:account/:login/authenticate' => 'authenticate#authenticate'
  end
end
