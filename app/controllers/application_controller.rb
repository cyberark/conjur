class ApplicationController < ActionController::API
  class Unauthorized < RuntimeError
  end
  
  rescue_from Unauthorized, with: :unauthorized

  def authentication_token
    Slosilo[:own].signed_token @user.login
  end
  
  def authentication
    @authentication ||= Authentication.new
  end
  
  def unauthorized e
    logger.info(e)
    head :unauthorized
  end
  
  def current_user?
    Conjur::Rack.identity?
  end
  
  def current_user
    Conjur::Rack.user
  end
end
