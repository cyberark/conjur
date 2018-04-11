AuthnLdap::Engine.routes.draw do
  constraints id: %r{[^\/\?]+} do
    post '/:service_id/:account/:login/authenticate' => 'authenticate#authenticate'
  end
end
