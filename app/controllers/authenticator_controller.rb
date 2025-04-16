# frozen_string_literal: true

class AuthenticatorController < ApplicationController
  include BasicAuthenticator
  include AuthorizeResource

  def list_authenticators
    allowed_params = %i[limit offset type account name]
    
    relevant_params = params.permit(*allowed_params)
      .slice(*allowed_params).to_h.symbolize_keys

    response = DB::Repository::AuthenticatorRepository.new(
      resource_repository: ::Resource.visible_to(current_user).search(
        **relevant_params.slice(:offset, :limit)
      )
    ).find_all(
      account: relevant_params[:account],
      type: relevant_params[:type]
    ).bind do |res|
      auths = res.map(&:to_h)
      ::SuccessResponse.new({ authenticators: auths, count: auths.count })
    end

    return render(json: response.result) if response.success?

    logger.debug("Exception: #{response.exception.class.name}: #{response.message}")
    head(response.status)
  rescue => e
    log_backtrace(e)
    raise e
  end

  def create_authenticator
    account = params[:account]
    auth_json = request.body.read
    auth = AuthenticatorsV2::AuthenticatorTypeFactory.new.create_authenticator_from_json(auth_json, account)
    unless auth.success?
      logger.debug("Failed to create authenticator from request params: #{auth.message}")
      head(auth.status)
      return
    end

    auth = auth.result
    # Ensure owner exists & requesting user has visibility on them
    begin
      ensure_owner_exists(auth.owner) unless auth.owner.nil?
    rescue Exceptions::RecordNotFound => e
      raise ApplicationController::UnprocessableEntity, e.message
    end

    begin
      # Attempt to create the authenticator in the database
      authenticator = DB::Repository::AuthenticatorRepository.new.create(authenticator: auth)
    rescue Sequel::UniqueConstraintViolation, Sequel::ConstraintViolation
      raise ApplicationController::Conflict, "The authenticator already exists."
    end

    render(json: authenticator.to_h)
  end

  def find_authenticator
    allowed_params = %i[type account service_id]
    
    relevant_params = params.permit(*allowed_params)
      .slice(*allowed_params).to_h.symbolize_keys

    response = DB::Repository::AuthenticatorRepository.new(
      resource_repository: ::Resource.visible_to(current_user)
    ).find(
      account: relevant_params[:account],
      type: relevant_params[:type],
      service_id: relevant_params[:service_id]
    ).bind do |res|
      break ::SuccessResponse.new(res.to_h) if current_user.allowed_to?('read', ::Resource[res.resource_id])

      ::FailureResponse.new( 
        "Forbidden",
        status: :forbidden,
        exception: Errors::Authorization::AccessToResourceIsForbiddenForRole
      )
    end

    return render(json: response.result) if response.success?

    logger.debug("Exception: #{response.exception.class.name}: #{response.message}")
    head(response.status)
  rescue => e
    log_backtrace(e)
    raise e
  end

  private

  def authorize_auth_branch(auth)
    auth_branch = "#{auth.account}:policy:#{auth.branch}"
    resource = Resource[auth.branch]
    raise Exceptions::RecordNotFound, auth_branch unless resource&.visible_to?(current_user)

    authorize(:create, auth_branch)
  end

  def ensure_owner_exists(owner_id)
    owner = Resource[owner_id]

    raise Exceptions::RecordNotFound, owner_id unless owner&.visible_to?(current_user)
  end
end
