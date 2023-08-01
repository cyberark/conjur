module Util
  class ContractUtils
    class << self
      def failed_response(error:, key:)
        key.failure(exception: error, text: error.message)
      end
    end
  end
end
