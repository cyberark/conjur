require 'types'

module Authentication
  class Security < ::Dry::Struct

    class NotWhitelisted < RuntimeError
      def initialize(authenticator_name)
        super("'#{authenticator_name}' not whitelisted in CONJUR_AUTHENTICATORS")
      end
    end

    class ServiceNotDefined < RuntimeError
      def initialize(service_name)
        super("Webservice '#{service_name}' is not defined in the Conjur policy")
      end
    end

    class NotAuthorizedInConjur < RuntimeError
      def initialize(user_id)
        super("User '#{user_id}' is not authorized in the Conjur policy")
      end
    end

    class AccessRequest < ::Dry::Struct
      attribute :webservice, ::Types.Instance(::Authentication::Webservice)
      attribute :whitelisted_webservices, 
        ::Types.Instance(::Authentication::Webservices)
      attribute :user_id, ::Types::NonEmptyString
    end

    # TODO figure out how to make test doubles of type class
    # attribute :role_class    , ::Types::Strict::Class
    # attribute :resource_class, ::Types::Strict::Class
    
    attribute :role_class, ::Types::Any.default(::Authentication::MemoizedRole)
    attribute :resource_class, ::Types::Any.default(Resource)

    def validate(access_request)
      validate_service_is_whitelisted(access_request)
      validate_user_has_access(access_request)
    end

    private

    def validate_service_is_whitelisted(req)
      is_whitelisted = req.whitelisted_webservices.include?(req.webservice)
      raise NotWhitelisted, req.webservice.name unless is_whitelisted
    end

    # TODO ideally, we'd break this up, and wrap resource_class and role_class
    #      in memoizing decorators.  the method is clear enough, though
    #
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
