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
    get  '/authn/login' => 'credentials#login'
    put  '/authn/password' => 'credentials#update_password'
    put  '/authn/api_key'  => 'credentials#rotate_api_key'

    constraints id: /[^\/\?]+/ do
      post '/authn/:id/authenticate' => 'authenticate#authenticate'
    end
    
    # TODO: this route exists for compatibility reasons only
    get "/roles/:account/:kind/*identifier" => "roles#members", :constraints => QueryParameterActionRecognizer.new("members"), :format => false

    get "/roles/:account/:kind/*identifier" => "roles#memberships", :constraints => QueryParameterActionRecognizer.new("all")
  
    get "/roles/:account/:kind/*identifier" => 'roles#check_permission', :constraints => QueryParameterActionRecognizer.new("check")
  
    get "/roles/:account/:kind/*identifier" => "roles#show"
  
    # TODO
    get "/roles/:account" => "roles#index"

    get "/resources/:account/:kind/*identifier" => 'resources#check_permission', :constraints => QueryParameterActionRecognizer.new("check")

    get "/resources/:account/:kind/*identifier" => 'resources#permitted_roles', :constraints => QueryParameterActionRecognizer.new("permitted_roles")
      
    get "/resources/:account/:kind/*identifier" => "resources#show"

    get "/resources/:account/:kind" => "resources#index"
    
    get "/resources/:account" => "resources#index"
  
    get "/secrets/:account/:kind/*identifier" => 'secrets#value'

    post "/secrets" => 'secrets#add_value'

    get "/pubkeys/:account/:kind/*identifier" => 'public_keys#show'

    get "/info" => "info#show"
  end
end
