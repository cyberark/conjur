# frozen_string_literal: true

module Authenticates
  extend ActiveSupport::Concern

  def authentication
    @authentication ||= Authenticate.new
  end
end
