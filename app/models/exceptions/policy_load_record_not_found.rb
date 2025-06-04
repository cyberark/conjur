# frozen_string_literal: true

module Exceptions
  # This exception is raised when a record required for policy loading is not found.
  # It is different from a standard RecordNotFound exception because it is used in the
  # context of policy loading, where the record not existing should be treated as a
  # validation error of the policy load object and return a 422 status code, rather
  # than a 404.
  class PolicyLoadRecordNotFound < RuntimeError
    attr_reader :id, :account, :kind, :identifier

    def initialize id, message: nil
      super(message || self.class.build_message(id))

      @id = id
      @account, @kind, @identifier = self.class.parse_id(id)
    end

    class << self
      def parse_id id
        id.split(':', 3)
      end

      def build_message id
        account, kind, id = parse_id(id)
        kind ||= 'unknown kind'
        account ||= 'unknown account'
        "#{kind.capitalize} '#{id}' not found in account '#{account}'"
      end
    end
  end
end
