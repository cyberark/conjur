# frozen_string_literal: true

class QueryParameterActionRecognizer
  def initialize(action)
    @action = action
  end

  def matches?(request)
    request.params.has_key?(@action)
  end
end

class ExcludeEncodedSlash
  def initialize(param)
    @param = param
  end

  def matches?(request)
    !request.params[@param].to_s.include?("/")
  end
end

Rails.application.routes.draw do
  scope format: false do
    get '/' => 'status#index'
    get '/whoami' => 'whoami#show'
    get '/authenticators' => 'authenticate#index'

    constraints id: /[^\/?]+/ do
      resources :accounts, only: [ :create, :index, :destroy ]
    end

    constraints account: /[^\/?]+/ do
      constraints(ExcludeEncodedSlash.new(:account)) do
        constraints authenticator: /authn-?[^\/]*/, id: /[^\/?]+/ do
          get '/authn-jwt/:service_id/:account/status' => 'authenticate#authn_jwt_status'
          get '/:authenticator(/:service_id)/:account/status' => 'authenticate#status'

          patch '/:authenticator(/:service_id)/:account' => 'authenticate#update_config'

          get '/:authenticator(/:service_id)/:account/login' => 'authenticate#login'

          constraints authenticator: /authn/ do
            post '/:authenticator/:account/:id/authenticate' => 'authenticate#authenticate_via_post'
          end

          constraints authenticator: /authn|authn-azure|authn-iam|authn-k8s|authn-ldap/ do
            post '/:authenticator(/:service_id)/:account/:id/authenticate' => 'authenticate#authenticate'
          end

          # New OIDC endpoint for code redirect authentication
          constraints authenticator: /authn-oidc/ do
            get '/:authenticator(/:service_id)/:account/authenticate' => 'authenticate#authenticate_via_get'
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
          get  '/:authenticator/:account/api_key'  => 'credentials#api_key_last_rotated'

          post '/authn-k8s/:service_id/inject_client_cert' => 'authenticate#k8s_inject_client_cert'
        end

        get '/authenticators/:account' => 'authenticator#list_authenticators'
        get '/authenticators/:account/:type/:service_id' => 'authenticator#find_authenticator'
        delete '/authenticators/:account/:type/:service_id' => 'authenticator#delete_authenticator'
        post '/authenticators/:account' => 'authenticator#create_authenticator'
        patch '/authenticators/:account/:type/:service_id' => 'authenticator#authenticator_enablement'

        # branch
        post "/branches/:account" => "branches#create"
        get "/branches/:account" => "branches#index"
        get "/branches/:account/*identifier" => "branches#show"
        patch "/branches/:account/*identifier" => "branches#update"
        delete "/branches/:account/*identifier" => "branches#delete"

        # groups
        post "/groups/:account/*identifier/members" => 'group_memberships#create'
        delete "/groups/:account/*identifier/members/:kind/(*id)" => 'group_memberships#delete'

        constraints kind: /user|host|layer|group|policy|host_factory/ do
          get     "/roles/:account/:kind/*identifier" => "roles#graph", :constraints => QueryParameterActionRecognizer.new("graph")
          get     "/roles/:account/:kind/*identifier" => "roles#all_memberships", :constraints => QueryParameterActionRecognizer.new("all")
          get     "/roles/:account/:kind/*identifier" => "roles#direct_memberships", :constraints => QueryParameterActionRecognizer.new("memberships")
          get     "/roles/:account/:kind/*identifier" => "roles#members", :constraints => QueryParameterActionRecognizer.new("members")
          post    "/roles/:account/:kind/*identifier" => "roles#add_member", :constraints => QueryParameterActionRecognizer.new("members")
          delete  "/roles/:account/:kind/*identifier" => "roles#delete_member", :constraints => QueryParameterActionRecognizer.new("members")
          get     "/roles/:account/:kind/*identifier" => "roles#show"
        end

        constraints kind: /variable|public_key|user|host|layer|group|policy|webservice|host_factory|configuration/ do
          get     "/resources/:account/:kind/*identifier" => 'resources#check_permission', :constraints => QueryParameterActionRecognizer.new("check")
          get     "/resources/:account/:kind/*identifier" => 'resources#permitted_roles', :constraints => QueryParameterActionRecognizer.new("permitted_roles")
          get     "/resources/:account/:kind/*identifier" => "resources#show"
          get     "/resources/:account/:kind"             => "resources#index"
          get     "/resources/:account"                   => "resources#index"
          get     "/resources"                            => "resources#index"
        end

        get     "/:authenticator/:account/providers"  => "providers#index"

        if Rails.application.config.feature_flags.enabled?(:dynamic_secrets)
          # Dynamic secrets
          # Issuers
          post    "/issuers/:account"             => 'issuers#create'
          delete  "/issuers/:account/:identifier" => 'issuers#delete'
          get     "/issuers/:account/:identifier" => 'issuers#get'
          get     "/issuers/:account"             => 'issuers#list'
          patch   "/issuers/:account/:identifier" => 'issuers#update'
        end

        # NOTE: the order of these routes matters: we need the expire
        #       route to come first.
        post    "/secrets/:account/:kind/*identifier" => "secrets#expire",
                :constraints => QueryParameterActionRecognizer.new("expirations")
        get     "/secrets/:account/:kind/*identifier" => 'secrets#show', constraints: { kind: /variable/ }
        post    "/secrets/:account/:kind/*identifier" => 'secrets#create', constraints: { kind: /variable|public_key/ }
        get     "/secrets"                            => 'secrets#batch'

        get     "/policies/:account/:kind/*identifier" => 'policies#get', constraints: { kind: /policy/ }
        put     "/policies/:account/:kind/*identifier" => 'policies#put', constraints: { kind: /policy/ }
        patch   "/policies/:account/:kind/*identifier" => 'policies#patch', constraints: { kind: /policy/ }
        post    "/policies/:account/:kind/*identifier" => 'policies#post', constraints: { kind: /policy/ }

        get     "/public_keys/:account/:kind/*identifier" => 'public_keys#show', constraints: { kind: /public_key|user/ }

        post     "/ca/:account/:service_id/sign" => 'certificate_authority#sign'
      end
    end

    # Customers can choose to disable these entirely
    if Rails.application.config.conjur_config.host_factories_enabled
      post    "/host_factories/hosts"    => 'host_factories#create_host'
      post    "/host_factory_tokens"     => 'host_factory_tokens#create'
      delete  "/host_factory_tokens/:id" => 'host_factory_tokens#destroy'
    end

    mount ConjurAudit::Engine, at: '/audit'
  end
end
