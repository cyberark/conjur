# frozen_string_literal: true

module Exceptions
  class RecordExists < RuntimeError
    attr_reader :kind, :id

    def initialize kind, id
      super("#{kind} '#{id}' already exists")

      @kind = kind
      @id = id
    end
  end
end
