require 'slosilo/adapters/abstract_adapter'

module Slosilo
  module Adapters
    class MemoryAdapter < AbstractAdapter
      def initialize
        @keys = {}
        @fingerprints = {}
      end
      
      def put_key id, key
        key = Slosilo::Key.new(key) if key.is_a?(String)
        @keys[id] = key
        @fingerprints[key.fingerprint] = id
      end
      
      def get_key id
        @keys[id]
      end

      def get_by_fingerprint fp
        id = @fingerprints[fp]
        [@keys[id], id]
      end
      
      def each(&block)
        @keys.each(&block)
      end
    end
  end
end
