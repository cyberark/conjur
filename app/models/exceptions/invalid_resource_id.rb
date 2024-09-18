# frozen_string_literal: true

module Exceptions
  class InvalidResourceId < RuntimeError
    def initialize resource_id
      super("Invalid resource ID: #{resource_id}. Valid IDs must be :account:kind:id.")
    end
  end
end
