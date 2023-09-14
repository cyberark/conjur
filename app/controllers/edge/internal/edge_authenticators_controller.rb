# frozen_string_literal: true

require_relative '../../../domain/edge_logic/authenticators/authenticators_manager'

class EdgeAuthenticatorsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include AuthenticatorsManager
  def all_authenticators
    logger.info(LogMessages::Endpoints::EndpointRequested.new("all-authenticators"))
    allowed_params = %i[account kind limit offset count]
    options = params.permit(*allowed_params).to_h.symbolize_keys

    begin
      verify_edge_host(options)
      verify_kind(options[:kind])
      kinds = options[:kind].split(',')
      if params[:count] == 'true'
        scope = get_authenticators_data(kinds)
        count_authenticators={}
        scope.each do |authenticator_kind, authenticators_list|
          count_authenticators[authenticator_kind] = authenticators_list.size
        end
        results = { count: count_authenticators }
        logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfullyWithCount.new("all-authenticators", params[:count]))
        render(json: results)
      else
        offset = options[:offset]
        limit = options[:limit]
        validate_scope(limit, offset)
        verify_header(request)
        response.set_header("Content-Encoding", "base64")
        parsed_data = get_authenticators_parsed_data(kinds, offset, limit)
        logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("all-authenticators"))
        render(json: parsed_data)
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
