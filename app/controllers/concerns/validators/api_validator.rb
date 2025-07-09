module APIValidator
  extend ActiveSupport::Concern

  def validate_header
    accept_header = request.headers["Accept"]
    unless accept_header
      raise Errors::Conjur::APIHeaderMissing, V2RestController::API_V2_HEADER
    end

    version_match = accept_header.match(%r{application/x\.secretsmgr\.v(\d+)beta\+json})
    version = version_match[1] if version_match
    return if version == "2"

    raise Errors::Conjur::APIHeaderMissing, V2RestController::API_V2_HEADER
  end
end
