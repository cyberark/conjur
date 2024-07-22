# frozen_string_literal: true

require 'exceptions/enhanced_policy'

class PoliciesController < RestController
  include FindResource
  include AuthorizeResource
  before_action :current_user
  before_action :find_or_create_root_policy
  after_action :publish_event, if: -> { response.successful? }

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load

  # Conjur policies are YAML documents, so we assume that if no content-type
  # is provided in the request.
  set_default_content_type_for_path(%r{^/policies}, 'application/x-yaml')

  def get
    action = :read
    unless params[:kind] == 'policy'
      raise(Errors::EffectivePolicy::PathParamError.new(params[:kind]))
    end
    authorize_ownership

    allowed_params = %i[account kind identifier depth limit]
    options = params.permit(*allowed_params)
      .slice(:account, :identifier, :depth, :limit).to_h.symbolize_keys
      .merge(role_id: current_user.id)

    resources = EffectivePolicy::GetEffectivePolicy.new(**options).verify.call
    policy_tree = EffectivePolicy::BuildPolicyTree.new.call(options[:identifier], resources)

    Audit.logger.log(Audit::Event::Policy.new(
      operation: action, subject: options,
      user: current_user, client_ip: request.ip,
      error_message: nil # No error message because reading was successful
    ))

    json_content_type = 'application/json'
    if request.headers["Content-Type"] == json_content_type
      render(plain: policy_tree.to_json, content_type: json_content_type)
    else
      render(plain: policy_tree.to_yaml, content_type: "application/x-yaml")
    end

  rescue Errors::EffectivePolicy::NumberParamError, Errors::EffectivePolicy::PathParamError => e
    audit_failure(e, action)
    raise ApplicationController::BadRequest, e.message
  rescue Errors::EffectivePolicy::PolicySizeExceeded => e
    audit_failure(e, action)
    raise ApplicationController::UnprocessableEntity, e.message
  rescue => e
    audit_failure(e, action)
    raise e
  end

  # A Conjur policy can be interpreted in various ways.
  # A production strategy guides the interpretation.
  # Loader::Orchestrate is a production that loads Conjur policy to database.
  # Loader::Validate is a production that parses Conjur policy, resulting in error reports.
  # The dryRun strategy parses Conjur policy, reports any errors, 
  #   and if valid, reports the effective policy changes.

  def production_type
    return :validation if params["dryRun"]&.strip&.downcase == "true"

    :orchestration
  end

  # Match API mode to policy mode.
  # Note: we prefer 'validation' as an argument name over 'validate'
  # to avoid conflict with the Gem validate method.

  def put
    load_policy(
      :update,
      Loader::ReplacePolicy,
      delete_permitted: true
    )
  end

  def patch
    load_policy(
      :update,
      Loader::ModifyPolicy,
      delete_permitted: true
    )
  end

  def post
    load_policy(
      :create,
      Loader::CreatePolicy,
      delete_permitted: false
    )
  end

  protected

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  private

  # Policy processing is a function of the policy mode request (load/update/replace) and
  # is interpreted using the Orchestrate strategy.

  def load_policy(mode, mode_class, delete_permitted:)
    # Authorization to load
    authorize(mode)
    mode_class.authorize(current_user, resource)

    # Parse the policy
    policy_parse = parse_submitted_policy

    # If this is not a dry run, then save the policy. This has to occur here,
    # as creating the policy_mode requires the policy_version
    policy_version = nil

    # Reporting on all policy errors requires an instance of the policy_mode
    # to call the #report method.
    policy_mode = mode_class.from_policy(
      policy_parse,
      policy_version,
      Loader::Validate
    )

    # Process the syntax of the policy. If it is invalid, an exception will
    # be thrown.
    policy_result = policy_mode.call
    raise policy_result.error if policy_result.error

    if production_type == :validation
      Rails.logger.debug("Begin operating in nested transaction...")
      Sequel::Model.db.transaction(savepoint: true) do # SAVEPOINT
        Rails.logger.debug("Operating in a nested transaction...")

        # If we've made it this far, the syntax of a policy is valid. Now we
        # perform the loading of policy.
        policy_version = save_submitted_policy(policy_parse, delete_permitted)
        policy_mode = mode_class.from_policy(
          policy_parse,
          policy_version,
          Loader::Orchestrate
        )
        policy_result = nil
        # Process the business logic of the policy. If it is invalid, an exception
        # will be thrown.
        policy_result = policy_mode.call
        raise policy_result.error if policy_result.error
        raise Sequel::Rollback
      end # ROLLBACK TO SAVEPOINT
      Rails.logger.debug("Transaction should've been rolled back...")
    else
      Rails.logger.debug("Skip operating in nested transaction...")
      policy_version = save_submitted_policy(policy_parse, delete_permitted)
      policy_mode = mode_class.from_policy(
        policy_parse,
        policy_version,
        Loader::Orchestrate
      )
      policy_result = nil
      # Process the business logic of the policy. If it is invalid, an exception
      # will be thrown.
      policy_result = policy_mode.call
      raise policy_result.error if policy_result.error
    end

    # If this is a dry run, we need to undo any changes to the database.
    # WARNING: this isn't ideal because we may need to access original
    # db state after rollback, however, a rollback does not occur until
    # the end of the transaction. We don't want to fetch all resources before
    # hand as we only want to fetch resources that we know have been changed.
    # rollback_dryrun()

    audit_success(policy_version)

    render(
      json: policy_mode.report(policy_result, production_type),
      status: success_status
    )
  # Sequel::ForeignKeyConstraintViolation and Exceptions::RecordNotFound are not
  # currently handled by the enhanced error framework, so we pass it directly up
  # to the application controller.
  rescue Sequel::ForeignKeyConstraintViolation, Exceptions::RecordNotFound => e
    audit_failure(e, mode)
    raise
  rescue => e
    # Processing errors can be explained the same as parsing errors,
    # but check whether the original is safe.
    load_err = e
    if e.instance_of?(Exceptions::EnhancedPolicyError)
      if e.original_error
        load_err = e.original_error
      end
    end

    # Errors caught here include those due to mode processing.
    audit_failure(e, mode)

    # If an error occurred before the policy_mode was instantiated, raise it
    # for the application controller to handle
    unless production_type == :validation
      raise load_err
    end

    # Render the errors according the mode (load or validate)
    render(
      json: policy_mode.report(policy_result, production_type),
      status: :unprocessable_entity
    )
  end

  def rollback_dryrun
    return unless production_type == :validation
    Sequel::Model.db.rollback_on_exit
    Rails.logger.debug("Rollback fired!")
  end

  def success_status
    production_type == :validation ? :ok : :created
  end

  # Auditing

  def audit_success(policy_version)
    case production_type
    when :validation
      audit_validation_success("validate")
    else
      audit_load_success(policy_version)
    end
  end

  def audit_load_success(policy_version)
    # Audit a successful policy load.
    policy_version.policy_log.lazy.map(&:to_audit_event).each do |event|
      Audit.logger.log(event)
    end
  end

  def audit_validation_success(mode)
    # Audit a successful validation.
    #
    # NOTE: this is created directly because we do not currently have a
    # PolicyVersion object that we can convert invoke `to_audit_event` on. When
    # we have this object, the audit log should be able to indicate at the
    # very least, which policy branch was validated.
    Audit.logger.log(
      Audit::Event::Policy.new(
        operation: mode,
        subject: {}, # Subject is empty because no role/resource has been impacted
        user: current_user,
        client_ip: request.ip,
        error_message: nil # No error message because validation was successful
      )
    )
  end

  def audit_failure(err, mode)
    Audit.logger.log(
      Audit::Event::Policy.new(
        operation: mode,
        subject: {}, # Subject is empty because no role/resource has been impacted
        user: current_user,
        client_ip: request.ip,
        error_message: err.message
      )
    )
  end

  def concurrent_load(_exception)
    response.headers['Retry-After'] = retry_delay
    render(
      json: {
        error: {
          code: "policy_conflict",
          message: "Concurrent policy load in progress, please retry"
        }
      },
      status: :conflict
    )
  end

  # Delay in seconds to advise the client to wait before retrying on conflict.
  # It's randomized to avoid request bunching.
  def retry_delay
    rand(1..8)
  end

  # Generate a version and parse the policy
  def save_submitted_policy(policy_parse, delete_permitted)
    # (SYSK: as with parse_submitted_policy, PolicyVersion
    # calls Commands::Policy::Parse, but it also generates
    # a policy version number and binds them in a db record.)

    policy_version = PolicyVersion.new(
      role: current_user,
      policy: resource,
      policy_text: request.raw_post,
      client_ip: request.ip,
      policy_parse: policy_parse
    )
    policy_version.delete_permitted = delete_permitted
    policy_version.save

    policy_version
  end

  # Parse the policy; no version is generated.
  def parse_submitted_policy
    # Commands::Policy::Parse catches errors related to policy validation

    policy = resource
    is_root = policy.kind == "policy" && policy.identifier == "root"

    Commands::Policy::Parse.new.call(
      account: policy.account,
      policy_id: policy.identifier,
      owner_id: policy.owner.id,
      policy_text: request.raw_post,
      policy_filename: nil,  # filename is historical and no longer informative
      root_policy: is_root
    )
  end

  def publish_event
    Monitoring::PubSub.instance.publish('conjur.policy_loaded')
  end
end
