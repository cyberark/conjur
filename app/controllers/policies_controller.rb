# frozen_string_literal: true
require 'command_class'

module Policy
  class LoadPolicy
    include AuthorizeResource
    extend CommandClass::Include

    command_class(
      dependencies: {
        loader_class: Loader::ModifyPolicy,
        audit_logger: ::Audit.logger,
        logger: Rails.logger
      },
      inputs: %i[delete_permitted action resource policy_text current_user client_ip]
    ) do

      def call
        auth(@current_user, @action, @resource)

        policy = save_submitted_policy(delete_permitted: @delete_permitted)
        loaded_policy = @loader_class.from_policy(policy)
        created_roles = perform(loaded_policy)
        audit_success(policy)

        return {created_roles: created_roles, policy: policy}
      rescue => e
        audit_failure(e, @action)
        raise e
      end

      protected

      def logger
        @logger
      end

      private

      def audit_success(policy)
        policy.policy_log.lazy.map(&:to_audit_event).each do |event|
          @audit_logger.log(event)
        end
      end

      def audit_failure(err, operation)
        @audit_logger.log(
          Audit::Event::Policy.new(
            operation: operation,
            subject: {}, # Subject is empty because no role/resource has been impacted
            user: @current_user,
            client_ip: @client_ip,
            error_message: err.message
          )
        )
      end

      # Delay in seconds to advise the client to wait before retrying on conflict.
      # It's randomized to avoid request bunching.
      def retry_delay
        rand(1..8)
      end

      def save_submitted_policy(delete_permitted:)
        policy_version = PolicyVersion.new(
          role: @current_user,
          policy: @resource,
          policy_text: @policy_text,
          client_ip: @client_ip
        )
        policy_version.delete_permitted = delete_permitted
        policy_version.save
      end

      def perform(policy_action)
        policy_action.call
        new_actor_roles = actor_roles(policy_action.new_roles)
        create_roles(new_actor_roles)
      end

      def actor_roles(roles)
        roles.select do |role|
          %w[user host].member?(role.kind)
        end
      end

      def create_roles(actor_roles)
        actor_roles.each_with_object({}) do |role, memo|
          credentials = Credentials[role: role] || Credentials.create(role: role)
          role_id = role.id
          memo[role_id] = { id: role_id, api_key: credentials.api_key }
        end
      end

    end
  end
end

class PoliciesController < RestController
  include FindResource
  include AuthorizeResource
  
  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  # Conjur policies are YAML documents, so we assume that if no content-type
  # is provided in the request.
  set_default_content_type_for_path(%r{^/policies}, 'application/x-yaml')

  def put
    load_policy(:update, Loader::ReplacePolicy, true)
  end

  def patch
    load_policy(:update, Loader::ModifyPolicy, true)
  end

  def post
    load_policy(:create, Loader::CreatePolicy, false)
  end

  def initialize_k8s_auth
    #TODO: Not a great way to set this value
    params[:authenticator] = "authn-k8s"
    initialize_auth_policy(template: params[:authenticator])

    #InitializeAuth::InitializeAuthCmd.new(auth_initializer: InitializeAuth::InitializeK8sAuth).(conjur_account: "testing", service_id: "test-id")

    Repos::ConjurCA.create("%s:webservice:conjur/authn-k8s/%s" % [ params[:account], params[:service_id] ] )

    unless json_body.empty?
      # TODO: Do we need to require ALL of these params or should we allow users to just set one/two
      require_body_parameters("service-account-token", "ca-cert", "api-url")

      Secret.create(resource_id: variable_id('kubernetes/service-account-token'), value: json_body['service-account-token'])
      Secret.create(resource_id: variable_id('kubernetes/ca-cert'), value: json_body['ca-cert'])
      Secret.create(resource_id: variable_id('kubernetes/api-url'), value: json_body['api-url']) 
    end
  rescue => e
    audit_failure(e, :update)
    raise e
  end

  def initialize_azure_auth
    params[:authenticator] = "authn-azure"
    require_body_parameters("provider-uri")
    initialize_auth_policy(template: params[:authenticator])

    Secret.create(resource_id: variable_id('provider-uri'), value: json_body['provider-uri'])
  rescue => e
    audit_failure(e, :update)
    raise e
  end

  def initialize_oidc_auth
    params[:authenticator] = "authn-oidc"
    require_body_parameters("provider-uri", "id-token-user-property")
    initialize_auth_policy(template: params[:authenticator])

    Secret.create(resource_id: variable_id('provider-uri'), value: json_body['provider-uri'])
    Secret.create(resource_id: variable_id('id-token-user-property'), value: json_body['id-token-user-property'])
  rescue => e
    audit_failure(e, :update)
    raise e
  end

  protected

  # Returns newly created roles
  def perform(policy_action)
    policy_action.call
    new_actor_roles = actor_roles(policy_action.new_roles)
    create_roles(new_actor_roles)
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  private

  def load_policy(action, loader_class, delete_permitted)
    details = Policy::LoadPolicy.new(loader_class: loader_class).(
      delete_permitted: delete_permitted,
      action: action,
      resource: resource,
      policy_text: request.raw_post,
      current_user: current_user,
      client_ip: request.ip
    )

    render(json: {
      created_roles: details[:created_roles],
      version: details[:policy].version
    }, status: :created)
  end

  def concurrent_load(_exception)
    response.headers['Retry-After'] = retry_delay
    render(json: {
      error: {
        code: "policy_conflict",
        message: "Concurrent policy load in progress, please retry"
      }
    }, status: :conflict)
  end
end
