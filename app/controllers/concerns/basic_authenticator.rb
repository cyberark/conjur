module BasicAuthenticator
  extend ActiveSupport::Concern
  
  def perform_basic_authn
    if request.authorization =~ /^Basic /
      Login::Provider::Basic.new(account, authentication, request).perform_login 
    end
  end
end
