require './app/domain/util/static_account'

class V2RestController < RestController
  include APIValidator

  before_action :validate_header
  before_action :current_user
  after_action  :update_response_header

  def update_response_header
    if response.headers['Content-Type'].nil?
      response.headers['Content-Type'] = 'application/x.secretsmgr.v2+json'
    else
      response.headers['Content-Type'] = response.headers['Content-Type'].sub('application/json', 'application/x.secretsmgr.v2+json')
    end
  end

  def account
    @account ||= StaticAccount.account
  end

  def resource_id(type, full_id)
    [ account, type, full_id ].join(":")
  end

  def resource(type, full_id)
    raise Exceptions::RecordNotFound, resource_id(type, full_id) unless resource_visible?(type, full_id)

    resource!(type, full_id)
  end

  def resource_exists?(type, full_id)
    Resource[resource_id(type, full_id)] ? true : false
  end

  private
  def resource_visible?(type, full_id)
    @resource_visible = resource!(type, full_id) && @resource.visible_to?(current_user)
  end

  def resource!(type, full_id)
    @resource = Resource[resource_id(type, full_id)]
  end
end