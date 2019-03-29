# frozen_string_literal: true

require 'dry-struct'

module CA
  # Facade for a Variable Conjur resource
  class Requestor < Dry::Struct::Value

    class << self
      def from_role(role)
        Requestor.new(
          identifier: role.identifier,
          account: role.account,
          kind: role.kind
        )
      end
    end

    attribute :identifier, Types::Strict::String
    attribute :account, Types::Strict::String
    attribute :kind, Types::Strict::String

    def id
      [
        account,
        kind,
        identifier
      ].join(':')
    end
  end
end
