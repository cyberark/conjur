# frozen_string_literal: true

class AuthenticatorController < ApplicationController
  include BasicAuthenticator
  include AuthorizeResource

  def list_authenticators
    response = DB::Repository::AuthenticatorRepository.new.find_all_if_visible(
      account: relevant_params[:account],
      type: relevant_params[:type],
      role: current_user,
      options: relevant_params.slice(:offset, :limit)
    ).bind do |res|
      auths = res.map(&:to_h)
      return render(json:  { authenticators: auths, count: auths.count })
    end

    logger.debug("Exception: #{response.exception.class.name}: #{response.message}")
    head(response.status)
  rescue => e
    log_backtrace(e)
    raise e
  end

  def relevant_params
    allowed_params = %i[limit offset type account]
    
    params.permit(*allowed_params)
      .slice(*allowed_params).to_h.symbolize_keys
  end
end
