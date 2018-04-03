require "authn_core/version"

module AuthnCore
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

      raise BadRequestError, "Invalid authn configuration" if @authn_type.empty? || @service_id.empty? || @user_id.empty?

      enabled? && service_exists? && user_exists? && user_authorized?
    end

    def enabled?
      authenticators = (ENV['CONJUR_AUTHENTICATORS'] || '').split(',').map(&:strip)
      unless authenticators.include?("authn-#{@authn_type}/#{@service_id}")
        raise NotFoundError, "authn-#{@authn_type}/#{@service_id} not whitelisted in CONJUR_AUTHENTICATORS"
      end
      return true
    end

    def service_exists?
      @service = conjur_api.resource("#{account}:webservice:conjur/authn-#{@authn_type}/#{@service_id}")

      unless @service.exists?
        raise NotFoundError, "Service #{@service_id} not found"
      end
      return true
    end

    def user_exists?
      unless user.exists?
        raise NotFoundError, "Role #{@user_id} not found"
      end
      return true
    end

    def user_authorized?
      unless @service.permitted?("authenticate")
        raise AuthenticationError, "#{@user_id} does not have 'authenticate' privilege on the conjur/authn-#{@authn_type}/#{@service_id} webservice"
      end
      return true
    end

    def user
      Conjur::API.role_from_username(conjur_api, @user_id, account)
    end

    def conjur_api
      @token = Conjur::API.authenticate_local "#{@user_id}"
      Conjur::API.new_from_token @token
    end

    def account
      ENV['CONJUR_ACCOUNT']
    end
  end
end
