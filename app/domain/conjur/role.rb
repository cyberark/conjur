# Represents a Conjur Role.
#
# This class contains the logic around converting to and from an id string,
# and anything other conventions we add.  Currently, this logic is spread
# and duplicated in many places.  This is an attempt to stop that.
module Conjur
  class Role
    attr_reader :account, :kind, :name

    def initialize(account:, kind:, name:)
      @account = account
      @kind = kind.to_s  # Allow accepting symbols
      @name = name
    end

    def from_id(full_id)
      pieces = full_id.split(":")
      unless pieces.size == 3
        raise ArgumentError, "Role ID format: <account>:<kind>:<name>"
      end
      acc, kind, name = full_id.split(":")
      self.class.new(account: acc, kind: kind, name: name)
    end

    def id
      [ account, kind, name ].join(",")
    end
  end
end
