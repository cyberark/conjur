# frozen_string_literal: true

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
    get '/whoami' => 'status#whoami'
    get '/health' => 'health#health'
    get '/authenticators' => 'authenticate#index'

    constraints id: /[^\/?]+/ do
      resources :accounts, only: [ :create, :index, :destroy ]
    end

    # Authenticators
    constraints account: /[^\/?]+/ do
      constraints authenticator: /authn-?[^\/]*/, id: /[^\/?]+/ do
        get '/authn-jwt/:service_id/:account/status' => 'authenticate#authn_jwt_status'
        get '/:authenticator(/:service_id)/:account/status' => 'authenticate#status'

        patch '/:authenticator(/:service_id)/:account' => 'authenticate#update_config'

        get '/:authenticator(/:service_id)/:account/login' => 'authenticate#login'

        constraints authenticator: /authn|authn-azure|authn-iam|authn-k8s|authn-ldap/ do
          post '/:authenticator(/:service_id)/:account/:id/authenticate' => 'authenticate#authenticate'
        end

        # New OIDC endpoint
        get '/:authenticator(/:service_id)/:account/authenticate' => 'authenticate#oidc_authenticate_code_redirect'

        post '/authn-gcp/:account/authenticate' => 'authenticate#authenticate_gcp'
        post '/authn-oidc(/:service_id)/:account/authenticate' => 'authenticate#authenticate_oidc'
        post '/authn-jwt/:service_id/:account(/:id)/authenticate' => 'authenticate#authenticate_jwt'

        # The API key this rotates is the internal Conjur API key. Because some
        # other authenticators will return this at login (e.g. LDAP), we want
        # this to be accessible when using other authenticators to login.
        put  '/:authenticator/:account/api_key'  => 'credentials#rotate_api_key'
      end

      # Factories
      post "/factories/:account/:kind/(:version)/:id" => "policy_factories#create"
      get "/factories/:account/:kind/(:version)/:id" => "policy_factories#show"
      get "/factories/:account" => "policy_factories#index"

      # Roles
      get     "/roles/:account/:kind/*identifier" => "roles#graph", :constraints => QueryParameterActionRecognizer.new("graph")
      get     "/roles/:account/:kind/*identifier" => "roles#all_memberships", :constraints => QueryParameterActionRecognizer.new("all")
      get     "/roles/:account/:kind/*identifier" => "roles#direct_memberships", :constraints => QueryParameterActionRecognizer.new("memberships")
      get     "/roles/:account/:kind/*identifier" => "roles#members", :constraints => QueryParameterActionRecognizer.new("members")
      post    "/roles/:account/:kind/*identifier" => "roles#add_member", :constraints => QueryParameterActionRecognizer.new("members")
      delete  "/roles/:account/:kind/*identifier" => "roles#delete_member", :constraints => QueryParameterActionRecognizer.new("members")
      get     "/roles/:account/:kind/*identifier" => "roles#show"

      # Resources
      get     "/resources/:account/:kind/*identifier" => 'resources#check_permission', :constraints => QueryParameterActionRecognizer.new("check")
      get     "/resources/:account/:kind/*identifier" => 'resources#permitted_roles', :constraints => QueryParameterActionRecognizer.new("permitted_roles")
      get     "/resources/:account/:kind/*identifier" => "resources#show"
      get     "/resources/:account/:kind"             => "resources#index"
      get     "/resources/:account"                   => "resources#index"
      get     "/resources"                            => "resources#index"

      # Workloads
      post    "hosts/:account/*identifier"            => "workload#post"

      # Secrets
      # NOTE: the order of these routes matters: we need the expire
      #       route to come first.
      post    "/secrets/:account/:kind/*identifier" => "secrets#expire",
        :constraints => QueryParameterActionRecognizer.new("expirations")
      get     "/secrets/:account/:kind/*identifier" => 'secrets#show'
      post    "/secrets/:account/:kind/*identifier" => 'secrets#create'
      get     "/secrets"                            => 'secrets#batch'

      # Edge
      post    "/edge/:account"                      => 'edge_creation#create_edge'
      delete  "/edge/:account/:identifier"          => 'edge_deletion#delete_edge'
      get     "/edge/secrets/:account"              => 'edge_secrets#all_secrets'
      get     "/edge/hosts/:account"                => 'edge_hosts#all_hosts'
      get     "/edge/authenticators/:account"       => 'edge_authenticators#all_authenticators'

      get     "edge/edge-creds/:account/:edge_name" => 'edge_creation#generate_install_token'
      get     "/edge/:account"                      => 'edge_visibility#all_edges'
      get     "/edge/max-allowed/:account"          => 'edge_configuration#max_edges_allowed'
      get     "/agent/validate-permission/:account"          => 'edge_configuration#validate_permission'

      post    "/edge/data/:account"                 => 'edge_handler#report_edge_data', :constraints => QueryParameterActionRecognizer.new("data_type")
      get     "/edge/slosilo_keys/:account"         => 'edge_slosilo_keys#slosilo_keys'

      # Feature flag
      get     "/features"                       => "feature_flag#feature_flag"

      # Ephemeral secrets
      post    "/issuers/:account"             => 'issuers#create'
      delete  "/issuers/:account/:identifier" => 'issuers#delete'
      get     "/issuers/:account/:identifier" => 'issuers#get'
      get     "/issuers/:account"             => 'issuers#list'

      # Policies
      put     "/policies/:account/:kind/*identifier" => 'policies#put'
      patch   "/policies/:account/:kind/*identifier" => 'policies#patch'
      post    "/policies/:account/:kind/*identifier" => 'policies#post'
    end

    # Host Factory
    post "/host_factories/hosts" => 'host_factories#create_host'
    post "/host_factory_tokens" => 'host_factory_tokens#create'
    delete "/host_factory_tokens/:id" => 'host_factory_tokens#destroy'

    mount ConjurAudit::Engine, at: '/audit'
  end
end
