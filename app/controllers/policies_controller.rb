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

  # A Conjur policy can be interpreted under various strategies.
  # Loader::Validate is a strategy that parses policy to look for lexical errors.
  # Loader::DryRun is a strategy that rehearses policy application and reports what would change.
  # Loader::Orchestrate is a strategy that actually does apply policy and store it to database.

  def strategy_type
    return :rehearsal if params["dryRun"]&.strip&.downcase == "true"

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

  def enhance_error(error)
    enhanced = error
    unless error.instance_of?(Exceptions::EnhancedPolicyError)
      enhanced = Exceptions::EnhancedPolicyError.new(
        original_error: error
      )
    end
    enhanced
  end

  # Policy processing is a function of the policy mode request (load/update/replace) and
  # is interpreted using strategies to match the user command.

  def load_policy(mode, mode_class, delete_permitted:)
    # A single instance of PolicyResult tracks policy progress and
    # is passed to successive operations.
    policy_result = PolicyResult.new
    policy_mode = nil

    # Declare above any vars that the lambdas need to recognize as local.

    # Has a policy error been encountered yet?
    policy_erred = lambda {
      !policy_result.nil? &&
      !policy_result.policy_parse.nil? &&
      !policy_result.policy_parse.error.nil?
    }

    # policy_mode is used to call loader methods
    get_policy_mode = lambda { |strategy_class|
      # mode = f(strategy, parse, version)
      policy_mode = mode_class.from_policy(
        policy_result.policy_parse,
        policy_result.policy_version,
        strategy_class
      )
    }
  
    # We wrap policy operations (parsing, loading, applying business rules)
    # in rescue blocks and capture the exceptions as the error results.
    # This prevents exceptions from rising uncontrollably (which would be a
    # problem in situations such as the dry-run rollback).
    evaluate_policy = lambda { |strategy_class|
      # load, raise, enhance
      begin
        get_policy_mode.call(strategy_class)
        policy_mode.call_pr(policy_result) unless policy_erred.call
      rescue => e
        policy_result.error=(enhance_error(e))
      end
    }

    # Evaluate policy until success or an error is encountered.
    # If errored, skip remaining evaluation and raise the error
    # to redirect to strategy-based report generation.

    authorize(mode)
    mode_class.authorize(current_user, resource)

    parse_submitted_policy(policy_result)

    if strategy_type == :rehearsal
      evaluate_policy.call(Loader::Validate)
      raise policy_result.error if policy_erred.call

      Sequel::Model.db.transaction(savepoint: true) do
        save_submitted_policy(policy_result, delete_permitted) unless policy_erred.call

        raise policy_result.error if policy_erred.call

        evaluate_policy.call(Loader::DryRun)

        raise Sequel::Rollback
      end

    else # :orchestration
      save_submitted_policy(policy_result, delete_permitted) unless policy_erred.call

      raise policy_result.error if policy_erred.call

      evaluate_policy.call(Loader::Orchestrate)

    end

    raise policy_result.error if policy_erred.call

    # Success
    audit_success(policy_result.policy_version)

    render(
      json: policy_mode.report(policy_result),
      status: strategy_type == :orchestration ? :created : :ok
    )

  # Error triage:
  # - Audit the original
  # - Report the enhanced
  # - Raise the original

  # Sequel::ForeignKeyConstraintViolation and Exceptions::RecordNotFound are not
  # currently handled by the enhanced error framework, so we pass it directly up
  # to the application controller.
  rescue Sequel::ForeignKeyConstraintViolation, Exceptions::RecordNotFound => e
    audit_failure(e, mode)
    raise e

  rescue => e
    original_error = e
    if e.instance_of?(Exceptions::EnhancedPolicyError)
      if e.original_error
        original_error = e.original_error
      end
    end

    audit_failure(original_error, mode)

    # Render Orchestration errors through ApplicationController
    raise original_error if strategy_type == :orchestration

    render(
      json: policy_mode.report(policy_result),
      status: :unprocessable_entity
    )

  end

  # Auditing

  def audit_success(policy_version)
    case strategy_type
    when :orchestration
      audit_load_success(policy_version)
    else
      audit_validation_success("validate")
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

  # Generate a version and parse the policy.
  # Returns a PolicyResult; errors related to version creation are packaged inside.
  # Raises no exceptions.
  def save_submitted_policy(policy_result, delete_permitted)
    version = nil
    begin
      version = PolicyVersion.new(
        role: current_user,
        policy: resource,
        policy_text: request.raw_post,
        client_ip: request.ip,
        policy_parse: policy_result.policy_parse
      )
      version.delete_permitted = delete_permitted
      version.save
    rescue => e
      policy_result.policy_parse = (PolicyParse.new([], enhance_error(e)))
    end
    policy_result.policy_version = (version)
  end

  # Parse the policy; no version is generated.
  # Returns a PolicyParse; errors, if any, are packaged inside.
  # Raises no exceptions.
  def parse_submitted_policy(policy_result)
    # Commands::Policy::Parse catches errors related to policy validation

    policy = resource
    is_root = policy.kind == "policy" && policy.identifier == "root"

    parse = Commands::Policy::Parse.new.call(
      account: policy.account,
      policy_id: policy.identifier,
      owner_id: policy.owner.id,
      policy_text: request.raw_post,
      policy_filename: nil,  # filename is historical and no longer informative
      root_policy: is_root
    )
    policy_result.policy_parse = (parse)
  end

  def publish_event
    Monitoring::PubSub.instance.publish('conjur.policy_loaded')
  end
end
