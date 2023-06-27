# frozen_string_literal: true

class HostsController < RestController
  include FindResource
  include AuthorizeResource
  include TemplatesRenderer

  before_action :current_user
  before_action :find_or_create_root_policy

  rescue_from Sequel::UniqueConstraintViolation, with: :concurrent_load
  def post
    authorize(:create)

  end
end