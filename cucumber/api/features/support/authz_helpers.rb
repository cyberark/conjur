# frozen_string_literal: true

# Utility methods for Authz steps
#
module AuthzHelpers
  def i_have_a_resource(kind, identifier, must_be_new: false)
    kind ||= "test-resource"
    identifier ||= random_hex
    identifier = denormalize identifier
    resource_id = "cucumber:#{kind}:#{identifier}"

    @resources ||= {}

    if Resource[resource_id: resource_id] && !must_be_new
      @current_resource = Resource[resource_id: resource_id]
    else
      @current_resource =
        Resource.create(resource_id: resource_id,
                        owner: @current_user || admin_user)
    end

    @resources[resource_id] = @current_resource
  end
end

World(AuthzHelpers)