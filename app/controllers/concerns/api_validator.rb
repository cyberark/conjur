module APIValidator extend ActiveSupport::Concern
  def validate_header
    accept_header = request.headers["Accept"]
    version_match = accept_header.match(/Api-Version=(\d+)/)
    version = version_match[1] if version_match
    unless version=="2"
      raise Errors::Conjur::APIHeaderMissing.new
    end
  end
end