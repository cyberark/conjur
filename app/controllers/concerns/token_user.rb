# frozen_string_literal: true

module TokenUser
  extend ActiveSupport::Concern

  def token_user?
    Conjur::Rack.identity?
  end
  
  def token_user
    Conjur::Rack.user
  end
end
