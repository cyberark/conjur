# frozen_string_literal: true

module Exceptions
  class InvalidRoleId < RuntimeError
    def initialize role_id 
      super("Invalid role ID: #{role_id}. Valid IDs must be account:kind:id")
    end
  end
end

