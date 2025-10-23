module Authenticators
  class Delete
    include AuthorizeResource
    
    def initialize(
      resource_repository: ::Resource,
      authn_repo: DB::Repository::AuthenticatorRepository
    )  
      @success = Responses::Success
      @failure = Responses::Failure
      @context = AuthenticatorController::Current
      @resource_repository = resource_repository
      @authn_repo = authn_repo.new(
        resource_repository: @resource_repository
      )
    end

    def call(type:, account:, service_id:)
      @authn_repo.find(type: type, account: account, service_id: service_id).bind do |auth|
        policy_id = auth.resource_id.gsub('webservice', 'policy')
        unless @context.user.allowed_to?('delete', ::Resource[policy_id])
          next @failure.new(
            "Unauthorized",
            status: :forbidden,
            exception: Exceptions::Forbidden
          )
        end
        policy =  @authn_repo.delete(policy_id: policy_id)
        @success.new(policy, status: :no_content)
      end
    end
  end
end
