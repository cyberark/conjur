# frozen_string_literal: true

module RequestContext
  extend ActiveSupport::Concern

  Context = Struct.new(:role, :request_ip, keyword_init: true)

  def context
    @context ||= generate_context
  end

  private

  def generate_context
    Context.new(
      role: current_user,
      request_ip: request.ip
    )
  end
end
