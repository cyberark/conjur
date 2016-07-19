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
    get  '/authn/users/login' => 'credentials#login'
    put  '/authn/users/password' => 'credentials#update_password'
    put  '/authn/users/api_key'  => 'credentials#rotate_api_key'
    delete  '/authn/users/clients/:client' => 'credentials#delete_client_keys'

    constraints id: /[^\/\?]+/ do
      post '/authn/users/:id/authenticate' => 'authenticate#authenticate'
    end
  end
  
  get "/authz/:account/roles/allowed_to/:permission/:kind/*identifier" => "resources#permitted_roles", :format => false
  
  get "/authz/:account/roles/:kind/*identifier" => "roles#memberships", :constraints => QueryParameterActionRecognizer.new("all"), :format => false

  get "/authz/:account/roles/:kind/*identifier" => 'roles#check_permission', :constraints => QueryParameterActionRecognizer.new("check"), :format => false

  get "/authz/:account/roles/:kind/*identifier" => "roles#members", :constraints => QueryParameterActionRecognizer.new("members"), :format => false

  get  "/authz/:account/resources/:kind/*identifier" => 'resources#check_permission', :constraints => QueryParameterActionRecognizer.new("check"), :format => false

  # TODO
  get "/authz/:account/roles/:kind/*identifier" => "roles#show", :format => false

  # TODO
  get "/authz/:account/roles" => "roles#index", :format => false
  
  get "/authz/:account/resources" => "resources#index", :format => false
  get "/authz/:account/resources/:kind" => "resources#index", :format => false

  get "/authz/:account/resources/:kind/*identifier" => "resources#show", :format => false

  get "/info" => "info#show"
end
