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
end
