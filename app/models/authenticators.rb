# frozen_string_literal: true

module Authenticators
  def get_authenticators
    begin
      authn_prefix = "webservice:conjur/authn-jwt/"
      records = Resource.where("resource_id LIKE ?", "%#{authn_prefix}%")
      records
    rescue => e
      raise e
    end
  end

end

