# frozen_string_literal: true

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

  # To avoid unexpected behavior, we check annotation keys for known policy attributes and ouput a warning if there is a match.
  KNOWN_POLICY_ATTRIBUTES = %w[
      id owner body user annotations restricted_to permit deny role privileges resource
      grant revoke member host-factory layers layer variable kind mime_type delete record
      group host webservice
    ].freeze

  def get
    action = :read

    authorize_ownership

    allowed_params = %i[account kind identifier depth limit]
    options = params.permit(*allowed_params)
      .slice(:account, :identifier, :depth, :limit).to_h.symbolize_keys
      .merge(role_id: current_user.id)

    resources = EffectivePolicy::GetEffectivePolicy.new(**options).verify.call
    policy_tree = EffectivePolicy::BuildPolicyTree.new.call(options[:identifier], resources)

    Audit.logger.log(
      Audit::Event::Policy.new(
        operation: action, subject: options,
        user: current_user, client_ip: request.ip,
        error_message: nil # No error message because reading was successful
      )
    )

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

  def enhance_error(error, policy_id: nil)
    context_policy_id = policy_id || resource&.identifier
    enhanced = error
    unless error.instance_of?(Exceptions::EnhancedPolicyError)
      enhanced = Exceptions::EnhancedPolicyError.new(
        original_error: error,
        additional_context: {
          policy_id: context_policy_id,
          offending_lines: extract_offending_lines(error)
        }
      )
    end
    enhanced
  end

  def extract_offending_lines(error)
    if error.respond_to?(:line)
      [error.line]
    else
      []
    end
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
        strategy_class,
        current_user
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
        e = sql_to_policy_error(e)
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

    response = policy_mode.report(policy_result)
    response[:warnings] = policy_result.warnings if policy_result.warnings.present?
    render(
      json: response,
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
    enhanced_error = e.is_a?(Exceptions::EnhancedPolicyError) ? e : enhance_error(e)
    if enhanced_error.instance_of?(Exceptions::EnhancedPolicyError) && enhanced_error.original_error
      original_error = enhanced_error.original_error
    end

    audit_failure(original_error, mode)

    # Render Orchestration errors through ApplicationController
    raise original_error if strategy_type == :orchestration

    # Render error response for validation
    error_json = policy_mode.report(policy_result)
    render(
      json: error_json,
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
    # Wrap parse error with EnhancedPolicyError if present and not already wrapped
    # Note: Parse command now adds context, so this is mainly a fallback
    if parse.error && !parse.error.is_a?(Exceptions::EnhancedPolicyError)
      parse.error = enhance_error(parse.error, policy_id: policy.identifier)
    end
    policy_result.policy_parse = (parse)

    annotation_names = parse.records.flat_map do |rec|
      rec.respond_to?(:annotations) && rec.annotations ? rec.annotations.keys : []
    end.uniq
    conflicts = annotation_names & KNOWN_POLICY_ATTRIBUTES
    if conflicts.any?
      policy_result.warnings ||= []
      conflicts.each do |conflict|
        policy_result.warnings << "Annotation '#{conflict}' matches a known policy attribute. This annotation will not be treated as a standard attribute and may not have the intended effect."
      end
    end
  end

  def publish_event
    Monitoring::PubSub.instance.publish('conjur.policy_loaded')
  end

  # This method is used to convert a Sequel::ForeignKeyConstraintViolation error
  # into a PolicyLoadRecordNotFound error.
  def sql_to_policy_error(exception)
    if !exception.is_a?(Sequel::ForeignKeyConstraintViolation) ||
        !exception.cause.is_a?(PG::ForeignKeyViolation)
      return exception
    end

    # Try to parse the error message to find the violating key. This is based on
    # `foreign_key_constraint_violation` in application_controller.rb.
    return exception unless exception.cause.result.error_field(PG::PG_DIAG_MESSAGE_DETAIL) =~ /Key \(([^)]+)\)=\(([^)]+)\) is not present in table "([^"]+)"/

    violating_key = ::Regexp.last_match(2)
    Exceptions::PolicyLoadRecordNotFound.new(violating_key)
  end
end
