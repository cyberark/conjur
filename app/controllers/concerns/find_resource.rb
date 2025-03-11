# frozen_string_literal: true

module FindResource
  extend ActiveSupport::Concern

  def get_resource(kind, identifier)
    resource = fetch_resource(kind, identifier)
    return resource if resource&.visible_to?(current_user)

    raise Exceptions::RecordNotFound, identifier
  end

  def check_res_not_conflict(kind, identifier)
    resource = fetch_resource(kind, identifier)

    raise Exceptions::RecordExists.new(kind, identifier) if resource
  end

  def fetch_resource(kind, identifier)
    resource_id = full_id(account, kind, res_identifier(identifier))
    Resource[resource_id]
  end

  def resource_id
    [ params[:account], params[:kind], params[:identifier] ].join(":")
  end

  protected

  def resource
    raise Exceptions::RecordNotFound, resource_id unless resource_visible?

    resource!
  end

  def resource_exists?
    Resource[resource_id] ? true : false
  end

  def resource_visible?
    @resource_visible ||= resource! && @resource.visible_to?(current_user)
  end

  private

  def resource!
    @resource ||= Resource[resource_id]
  end
end
