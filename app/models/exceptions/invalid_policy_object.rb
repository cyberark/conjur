# frozen_string_literal: true

module Exceptions
  class InvalidPolicyObject < RuntimeError
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
        "The policy definition for #{kind.capitalize} '#{id}' is not valid"
      end
    end
  end
end
