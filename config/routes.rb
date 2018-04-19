class QueryParameterActionRecognizer
  def initialize(action)
    @action = action
  end

  def matches?(request)
    request.params.has_key?(@action)
  end
end

Rails.application.routes.draw do
  scope format: false do
    get '/' => 'status#index'

    constraints id: /[^\/\?]+/ do
      resources :accounts, only: [ :create, :index, :destroy ]
    end

    constraints account: /[^\/\?]+/ do
      get  '/authn/:account/login' => 'credentials#login'
      put  '/authn/:account/password' => 'credentials#update_password'
      put  '/authn/:account/api_key'  => 'credentials#rotate_api_key'

      constraints id: /[^\/\?]+/ do
        post '/:authenticator(/:service_id)/:account/:id/authenticate' =>
          'authenticate#authenticate'
      end

      get "/roles/:account/:kind/*identifier" => "roles#memberships", :constraints => QueryParameterActionRecognizer.new("all")

      get "/roles/:account/:kind/*identifier" => "roles#show"

      get "/resources/:account/:kind/*identifier" => 'resources#check_permission', :constraints => QueryParameterActionRecognizer.new("check")

      get "/resources/:account/:kind/*identifier" => 'resources#permitted_roles', :constraints => QueryParameterActionRecognizer.new("permitted_roles")

      get "/resources/:account/:kind/*identifier" => "resources#show"

      get "/resources/:account/:kind" => "resources#index"

      get "/resources/:account" => "resources#index"

      get "/resources" => "resources#index"

      get "/secrets/:account/:kind/*identifier" => 'secrets#show'

      post "/secrets/:account/:kind/*identifier" => 'secrets#create'

      get "/secrets" => 'secrets#batch'

      put "/policies/:account/:kind/*identifier" => 'policies#put'

      patch "/policies/:account/:kind/*identifier" => 'policies#patch'

      post "/policies/:account/:kind/*identifier" => 'policies#post'

      get "/public_keys/:account/:kind/*identifier" => 'public_keys#show'
    end

    post "/host_factories/hosts" => 'host_factories#create_host'

    post "/host_factory_tokens" => 'host_factory_tokens#create'

    delete "/host_factory_tokens/:id" => 'host_factory_tokens#destroy'
  end

end
