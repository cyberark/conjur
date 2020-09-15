# frozen_string_literal: true

# Utility methods for Authz steps
#
module AuthzHelpers
  def i_have_a_resource(kind, identifier)
    kind        ||= "test-resource"
    identifier  ||= random_hex
    identifier  = denormalize identifier
    resource_id = "cucumber:#{kind}:#{identifier}"

    @resources ||= {}

    @current_resource = Resource[resource_id: resource_id]
    unless @current_resource
      @current_resource = Resource.create(resource_id: resource_id,
                                          owner: @current_user || admin_user)
    end

    @resources[resource_id] = @current_resource
  end

  def i_have_a_new_resource(kind, identifier)
    kind        ||= "test-resource"
    identifier  ||= random_hex
    identifier  = denormalize identifier
    resource_id = "cucumber:#{kind}:#{identifier}"

    @resources ||= {}

    @current_resource = Resource.create(resource_id: resource_id,
                                        owner:       @current_user || admin_user)

    @resources[resource_id] = @current_resource
  end

  def set_annotation_to_resource(name, value, resource = @current_resource)
    unless resource.annotations.find { |a| a.values[:name] == name }
      resource.add_annotation name: name, value: value
    end
  end

  def remove_resource_all_annotations(resource = @current_resource)
    resource.annotations.each { |a| a.delete }
  end
end

World(AuthzHelpers)
