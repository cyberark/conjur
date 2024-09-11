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

  def parse_resource_id(resource_id, v2_syntax: false)
    if resource_id.nil? || resource_id&.count(':') != 2
      raise Exceptions::InvalidResourceId, resource_id
    end

    account, type, full_id = resource_id.split(':')
    branch, _, name = full_id.rpartition('/')
    if branch.empty? 
      branch = 'root'
    end
    type = Util::V2Helpers.translate_kind(type) if v2_syntax 
    { account: account, type: type, branch: branch, name: name, id: full_id }
  end

  def get_resource(type, resource_id)
    full_resource_id = full_resource_id(type, resource_id)
    resource = Resource[full_resource_id]
    raise Exceptions::RecordNotFound, full_resource_id unless resource

    resource
  end
end
