require 'types'
require 'util/error_class'
require 'authentication/webservice'
require 'authentication/webservices'

module Authentication
  class Security < ::Dry::Struct

    NotWhitelisted = ::Util::ErrorClass.new(
      "'{0}' not whitelisted in CONJUR_AUTHENTICATORS")
    ServiceNotDefined = ::Util::ErrorClass.new(
      "Webservice '{0}' is not defined in the Conjur policy")
    NotAuthorizedInConjur = ::Util::ErrorClass.new(
      "User '{0}' is not authorized in the Conjur policy")

    class AccessRequest < ::Dry::Struct
      attribute :webservice, ::Types.Instance(::Authentication::Webservice)
      attribute :whitelisted_webservices, 
        ::Types.Instance(::Authentication::Webservices)
      attribute :user_id, ::Types::NonEmptyString

      def validate
        is_whitelisted = whitelisted_webservices.include?(webservice)
        raise NotWhitelisted, webservice.name unless is_whitelisted
      end
    end

    attribute :role_class, ::Types::Any.default { ::Authentication::MemoizedRole }
    attribute :resource_class, ::Types::Any.default { ::Resource }

    def validate(access_request)
      # No checks required for default conjur auth
      return if default_conjur_authn?(access_request)

      access_request.validate
      validate_user_has_access(access_request)
    end

    private

    def default_conjur_authn?(req)
      req.webservice.authenticator_name ==
        ::Authentication::Strategy.default_authenticator_name
    end

    def validate_user_has_access(req)
      # Ensure webservice is defined in Conjur
      webservice_resource = resource_class[req.webservice.resource_id]
      raise ServiceNotDefined, req.webservice.name unless webservice_resource

      # Ensure user is defined in Conjur
      account      = req.webservice.account
      user_role_id = role_class.roleid_from_username(account, req.user_id)
      user_role    = role_class[user_role_id]
      raise NotAuthorizedInConjur, req.user_id unless user_role

      # Ensure user has access to the service
      has_access = user_role.allowed_to?('authenticate', webservice_resource)
      raise NotAuthorizedInConjur, req.user_id unless has_access
    end
  end

end
