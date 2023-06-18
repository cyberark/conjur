require 'slosilo/adapters/abstract_adapter'

module Slosilo
  module Adapters
    class FileAdapter < AbstractAdapter
      attr_reader :dir
      
      def initialize(dir)
        @dir = dir
        @keys = {}
        @fingerprints = {}
        Dir[File.join(@dir, "*.key")].each do |f|
          key = Slosilo::EncryptedAttributes.decrypt File.read(f)
          id = File.basename(f, '.key')
          key = @keys[id] = Slosilo::Key.new(key)
          @fingerprints[key.fingerprint] = id
        end
      end
      
      def put_key id, value
        raise "id should not contain a period" if id.index('.')
        fname = File.join(dir, "#{id}.key")
        File.write(fname, Slosilo::EncryptedAttributes.encrypt(value.to_der))
        File.chmod(0400, fname)
        @keys[id] = value
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
