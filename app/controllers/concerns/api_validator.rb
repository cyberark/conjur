module APIValidator extend ActiveSupport::Concern
  def validate_header
    accept_header = request.headers["Accept"]
    version_match = accept_header.match(/application\/x\.secretsmgr\.v(\d+)\+json/)
    version = version_match[1] if version_match
    unless version=="2"
      logger.debug(Errors::Conjur::APIHeaderMissing.new.message)
    end
  end
end