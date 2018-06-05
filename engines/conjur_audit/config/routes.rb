ConjurAudit::Engine.routes.draw do
  scope format: false do
    root 'messages#index'
    get '/resources/:resource' => 'messages#index'
    get '/roles/:role' => 'messages#index'
    get '/entities/:entity' => 'messages#index'
  end
end
