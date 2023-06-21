module Slosilo
  module Adapters
    class MockAdapter < Hash
      def initialize
        @fp = {}
      end

      def put_key id, key
        @fp[key.fingerprint] = id
        self[id] = key
      end

      alias :get_key :[]

      def get_by_fingerprint fp
        id = @fp[fp]
        [self[id], id]
      end
    end
  end
end
