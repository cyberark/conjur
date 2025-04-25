# frozen_string_literal: true

require 'singleton'
require_relative 'domain'

module Domain
  class OwnerService
    include Singleton
    include Domain

    def initialize(
      role_repository: ::Role
    )
      @role_repository = role_repository
    end

    def resource_owner(parent_identifier, owner)
      return Owner.new(owner.kind, owner.id) if owner.set?

      Owner.new(
        root?(parent_identifier) ? 'user' : 'policy', # kind
        root?(parent_identifier) ? 'admin' : parent_identifier # id
      )
    end

    def check_owner_exists(account, owner)
      role_id = full_id(account, owner.kind, res_identifier(owner.id))
      role = @role_repository[role_id]
      return owner unless role.nil?

      raise Exceptions::RecordNotFound, role_id
    end
  end
end
