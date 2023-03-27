# frozen_string_literal: true

# FindRole is a wrapper over FindResource to provide a Role instance for the
# given Resource ID.
module FindRole
  extend ActiveSupport::Concern

  included do
    include FindResource
  end

  def role_id
    # Use FindResource#resource_id
    resource_id
  end

  protected

  def role
    # Use FindResource#resource_visible? to determine Role visibility
    raise Exceptions::RecordNotFound, role_id unless resource_visible?

    role!
  end

  private

  def role!
    @role ||= Role[role_id]
  end
end
