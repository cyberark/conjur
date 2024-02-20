require './app/domain/util/static_account'

module ResourcesHandler
  def account
    @account ||= StaticAccount.account
  end

  def full_resource_id(type, full_id)
    #We support the path to start with / and without but for full id we need it without /
    if full_id.start_with?("/")
      full_id = full_id[1..-1]
    end
    [ account, type, full_id ].join(":")
  end

  def get_resource(type, resource_id)
    full_resource_id = full_resource_id(type, resource_id)
    resource = Resource[full_resource_id]
    raise Exceptions::RecordNotFound, full_resource_id unless resource

    resource
  end
end