module Authenticator
  class Create
    include AuthorizeResource
    
    def initialize(
      factory: AuthenticatorsV2::AuthenticatorTypeFactory.new,
      resource_repository: ::Resource,
      logger: Rails.logger,
      authn_repo: DB::Repository::AuthenticatorRepository
    )  
      @facotry = factory
      @logger = logger
      @success = ::SuccessResponse
      @failure = ::FailureResponse
      @context = AuthenticatorController::Current
      @resource_repository = resource_repository
      @authn_repo = authn_repo.new(
        resource_repository: @resource_repository
      )
    end

    def call(auth_dict, account)
      @facotry.create_authenticator_from_json(auth_dict, account).bind do |auth| 
        validate_create_permissions(auth).bind do |permitted_auth|
          verify_owner(permitted_auth).bind do |auth_with_owner|
            @authn_repo.create(authenticator: auth_with_owner).bind do |created_auth|
              @success.new(created_auth.to_h)
            end
          end 
        end
      end
    end

    private

    def validate_create_permissions(auth)
      auth_branch = "#{auth.account}:policy:#{auth.branch}"
      resource = Resource[auth_branch]
      
      unless resource&.visible_to?(@context.user) 
        return @failure.new(
          "#{auth_branch} not found in account #{auth.account}",
          exception: Exceptions::RecordNotFound.new(auth_branch),
          status: :not_found
        )
      end
      authorized?(:create, resource)
      @success.new(auth) 
    end

    def verify_owner(auth)
      return ensure_owner_exists(auth) unless auth.owner.nil?
  
      @success.new(auth)
    end
  
    def ensure_owner_exists(auth)
      owner = Resource[auth.owner]
      return @success.new(auth) if owner&.visible_to?(@context.user) 
  
      @failure.new(
        "#{auth.owner} not found in account #{auth.account}",
        exception: Exceptions::RecordNotFound.new(auth.owner),
        status: :not_found
      )
    end

    def  authorized?(privilege, resource)
      return if @context.user.allowed_to?(privilege, resource)
      
      @logger.info(
        Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
          @context.user.role_id,
          privilege,
          resource.resource_id
        )
      )

      raise ApplicationController::Forbidden
    end
  end
end
