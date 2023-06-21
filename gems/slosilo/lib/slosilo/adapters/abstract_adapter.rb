require 'slosilo/attr_encrypted'

module Slosilo
  module Adapters
    class AbstractAdapter
      def get_key id
        raise NotImplementedError
      end
      
      def get_by_fingerprint fp
        raise NotImplementedError
      end

      def put_key id, key
        raise NotImplementedError
      end
      
      def each
        raise NotImplementedError
      end
    end
  end
end
