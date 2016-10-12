module Exceptions
  class RecordNotFound < RuntimeError
    attr_reader :id

    def initialize id, message = nil
      super message || self.class.build_message(id)

      @id = id
    end

    class << self
      def build_message id
        account, kind, id = id.split(':', 3)
        "#{kind.capitalize} '#{id}' not found in account '#{account}'"
      end
    end
  end
end
