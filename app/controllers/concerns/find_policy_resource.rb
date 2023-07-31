# frozen_string_literal: true
module FindPolicyResource
  extend ActiveSupport::Concern

  def resource_id(location)
    [ params[:account], "policy", location ].join(":")
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy(account)
  end

  def account
    @account ||= params[:account]
  end


  protected

  def resource(location)
    raise Exceptions::RecordNotFound, resource_id(location) unless resource_visible?(location)

    resource!(location)
  end

  def resource_exists?(location)
    Resource[resource_id(location)] ? true : false
  end

  def resource_visible?(location)
    @resource_visible = resource!(location) && @resource.visible_to?(current_user)
  end

  private

  def resource!(location)
    @resource = Resource[resource_id(location)]
  end

end