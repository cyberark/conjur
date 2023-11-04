# frozen_string_literal: true

require_relative '../../../domain/edge_logic/authenticators/authenticators_manager'

class EdgeAuthenticatorsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include AuthenticatorsManager
  def all_authenticators
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("all-authenticators replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"))
    allowed_params = %i[account kind limit offset count]
    options = params.permit(*allowed_params).to_h.symbolize_keys

    begin
      verify_edge_host(options)
      verify_kind(options[:kind])
      kinds = options[:kind].split(',')
      if params[:count] == 'true'
        generate_count_response(kinds)
      else
        generate_auth_response(kinds, options)
      end
    rescue ApplicationController::Forbidden
      raise
    rescue ArgumentError => e
      raise ApplicationController::UnprocessableEntity, e.message
    rescue => e
      raise ApplicationController::InternalServerError, e.message
    end
  end

  private

  def generate_auth_response(kinds, options)
    offset = options[:offset]
    limit = options[:limit]
    validate_scope(limit, offset)
    verify_header(request)
    response.set_header("Content-Encoding", "base64")
    parsed_data = get_authenticators_parsed_data(kinds, offset, limit)
    render(json: parsed_data)
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
      "all-authenticators replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"))
  end

  def generate_count_response(kinds)
    scope = get_authenticators_data(kinds)
    count_authenticators = {}
    scope.each do |authenticator_kind, authenticators_list|
      count_authenticators[authenticator_kind] = authenticators_list.size
    end
    results = { count: count_authenticators }
    render(json: results)
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfullyWithCount.new(
      "all-authenticators replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'", params[:count]))
  end

  def verify_kind(kinds_param)
    allowed_kind = ['authn-jwt']
    kinds = kinds_param.to_s.split(',')
    # the kind param cant be empty, and the values have to be from the allowed_kind list
    unless kinds.present? && kinds.all? { |value| allowed_kind.include?(value) }
      raise ArgumentError , "authenticator kind parameter is not valid"
    end
  end
  def verify_header(request)
    accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
    unless accepts_base64
      raise InternalServerError , "the header request must contain base64 accept-encoding"
    end
  end

end
