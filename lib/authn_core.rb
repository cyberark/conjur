require 'conjur-api'

class AuthnCore

  class BadRequestError < RuntimeError
  end

  class NotFoundError < RuntimeError
  end

  class AuthenticationError < RuntimeError
  end

  # required info:
  # service_id, authn_type, user_id (which might be host/host_id)
  class << self
    def authorized? authn_type, service_id, user_id
      @authn_type = authn_type
      @service_id = service_id
      @user_id = user_id

      raise BadRequestError, "Invalid authn configuration" if @authn_type.nil? || @service_id.nil? || @user_id.nil?

      enabled? && service_exists? && user_exists? && user_authorized?    
    end

    def enabled?
      authenticators = (ENV['CONJUR_AUTHENTICATORS'] || '').split(',').map(&:strip)
      unless authenticators.include?("authn-#{@authn_type}/#{@service_id}")
        raise NotFoundError, "authn-#{@authn_type}/#{@service_id} not whitelisted in CONJUR_AUTHENTICATORS"
      end
    end

    def service_exists?
      @service ||= user_api_client.resource("webservice:conjur/authn-#{@authn_type}/#{@service_id}")
    raise NotFoundError, "Service #{@service_id} not found" unless @service.exists?
    end

    def user_exists?
      raise NotFoundError, "Role #{user.id} not found" unless user.exists?
    end

    def user_authorized?
      raise AuthenticationError, "#{user.roleid} does not have 'authenticate' privilege on #{@service.resourceid}" unless @service.permitted?("authenticate")
    end

    def user
      @user ||= user_api_client.user(@user_id)
    end

    def user_api_client
      @user_api_client ||= Conjur::API.new_from_token user_token
    end

    def user_token
      @user_token ||= Conjur::API.authenticate_local "#{@user_id}"
    end
  end
end
