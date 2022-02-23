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
    get '/authenticators' => 'authenticate#index'

    constraints id: /[^\/?]+/ do
      resources :accounts, only: [ :create, :index, :destroy ]
    end

    constraints account: /[^\/?]+/ do
      constraints authenticator: /authn-?[^\/]*/, id: /[^\/?]+/ do
        get '/authn-jwt/:service_id/:account/status' => 'authenticate#authn_jwt_status'
        get '/:authenticator(/:service_id)/:account/status' => 'authenticate#status'

        patch '/:authenticator(/:service_id)/:account' => 'authenticate#update_config'

        get '/:authenticator(/:service_id)/:account/login' => 'authenticate#login'

        constraints authenticator: /authn|authn-azure|authn-iam|authn-k8s|authn-ldap/ do
          post '/:authenticator(/:service_id)/:account/:id/authenticate' => 'authenticate#authenticate'
        end

        post '/authn-gcp/:account/authenticate' => 'authenticate#authenticate_gcp'
        post '/authn-oidc(/:service_id)/:account/authenticate' => 'authenticate#authenticate_oidc'
        post '/authn-jwt/:service_id/:account(/:id)/authenticate' => 'authenticate#authenticate_jwt'

        # Update password is only relevant when using the default authenticator
        put  '/authn/:account/password' => 'credentials#update_password', defaults: { authenticator: 'authn' }

        # The API key this rotates is the internal Conjur API key. Because some
        # other authenticators will return this at login (e.g. LDAP), we want
        # this to be accessible when using other authenticators to login.
        put  '/:authenticator/:account/api_key'  => 'credentials#rotate_api_key'

        post '/authn-k8s/:service_id/inject_client_cert' => 'authenticate#k8s_inject_client_cert'

        constraints authenticator: /authn-azure|authn-k8s|authn-oidc|authn-iam|authn-ldap/ do
          post '/:authenticator(/:service_id)/:account' => 'authenticators#persist_auth', defaults: { service_id: 'authenticator' }
          post '/:authenticator(/:service_id)/:account/host' => 'authenticators#persist_auth_host', defaults: { service_id: 'authenticator' }
        end

        post '/authn-gcp/:account' => 'authenticators#persist_gcp_auth', defaults: { authenticator: 'authn-gcp' }
        post '/authn-gcp/:account/host' => 'authenticators#persist_gcp_auth_host', defaults: { authenticator: 'authn-gcp' }
      end

      get     "/roles/:account/:kind/*identifier" => "roles#graph", :constraints => QueryParameterActionRecognizer.new("graph")
      get     "/roles/:account/:kind/*identifier" => "roles#all_memberships", :constraints => QueryParameterActionRecognizer.new("all")
      get     "/roles/:account/:kind/*identifier" => "roles#direct_memberships", :constraints => QueryParameterActionRecognizer.new("memberships")
      get     "/roles/:account/:kind/*identifier" => "roles#members", :constraints => QueryParameterActionRecognizer.new("members")
      post    "/roles/:account/:kind/*identifier" => "roles#add_member", :constraints => QueryParameterActionRecognizer.new("members")
      delete  "/roles/:account/:kind/*identifier" => "roles#delete_member", :constraints => QueryParameterActionRecognizer.new("members")
      get     "/roles/:account/:kind/*identifier" => "roles#show"

      get     "/resources/:account/:kind/*identifier" => 'resources#check_permission', :constraints => QueryParameterActionRecognizer.new("check")
      get     "/resources/:account/:kind/*identifier" => 'resources#permitted_roles', :constraints => QueryParameterActionRecognizer.new("permitted_roles")
      get     "/resources/:account/:kind/*identifier" => "resources#show"
      get     "/resources/:account/:kind"             => "resources#index"
      get     "/resources/:account"                   => "resources#index"
      get     "/resources"                            => "resources#index"

      # NOTE: the order of these routes matters: we need the expire
      #       route to come first.
      post    "/secrets/:account/:kind/*identifier" => "secrets#expire",
        :constraints => QueryParameterActionRecognizer.new("expirations")
      get     "/secrets/:account/:kind/*identifier" => 'secrets#show'
      post    "/secrets/:account/:kind/*identifier" => 'secrets#create'
      get     "/secrets"                            => 'secrets#batch'

      put     "/policies/:account/:kind/*identifier" => 'policies#put'
      patch   "/policies/:account/:kind/*identifier" => 'policies#patch'
      post    "/policies/:account/:kind/*identifier" => 'policies#post'

      get     "/public_keys/:account/:kind/*identifier" => 'public_keys#show'

      post     "/ca/:account/:service_id/sign" => 'certificate_authority#sign'
    end

    post "/host_factories/hosts" => 'host_factories#create_host'
    post "/host_factory_tokens" => 'host_factory_tokens#create'
    delete "/host_factory_tokens/:id" => 'host_factory_tokens#destroy'

    mount ConjurAudit::Engine, at: '/audit'
  end
end
