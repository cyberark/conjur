class QueryParameterActionRecognizer
  def initialize(action)
    @action = action
  end

  def matches?(request)
    request.params.has_key?(@action)
  end
end

Rails.application.routes.draw do
  # error pages
  %w( 500 ).each do |code|
    get code, :to => "errors#show", :code => code
  end
  
  scope format: false do
    get  '/authn/users/login' => 'credentials#login'
    put '/authn/users/password' => 'credentials#update_password'
    put '/authn/users/api_key'  => 'credentials#rotate_api_key'

    constraints id: /[^\/\?]+/ do
      post '/authn/users/:id/authenticate' => 'authenticate#authenticate'
    end
  end
  
  # Works
  get "/authz/:account/roles/allowed_to/:permission/:kind/*identifier" => "resources#permitted_roles", :format => false
  
  get "/authz/:account/roles/:kind" => "roles#all_roles", :constraints => QueryParameterActionRecognizer.new("all"), :format => false
  get "/authz/:account/roles/:kind/*identifier" => "roles#all_roles", :constraints => QueryParameterActionRecognizer.new("all"), :format => false

  # Works  
  get "/authz/:account/roles/:kind/*identifier" => 'roles#check_permission', :constraints => QueryParameterActionRecognizer.new("check"), :format => false

  get "/authz/:account/roles" => "roles#index", :format => false

  get "/authz/:account/roles/:kind/*identifier" => "roles#list_members", :constraints => QueryParameterActionRecognizer.new("members"), :format => false

  get "/authz/:account/roles/:kind/*identifier" => "roles#show", :format => false

  # Works
  get  "/authz/:account/resources/:kind/*identifier" => 'resources#check_permission', :constraints => QueryParameterActionRecognizer.new("check"), :format => false
  
  # Works
  get "/authz/:account/resources" => "resources#index", :format => false
  # Works
  get "/authz/:account/resources/:kind" => "resources#index", :format => false

  # Works
  get "/authz/:account/resources/:kind/*identifier" => "resources#show", :format => false

  post "/audit" => "audit#inject_audit_event"
end
