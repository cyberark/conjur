module Util
  module WebSocket
    class WithAttributes < SimpleDelegator
      def initialize(ws, attrs_hash)
        super(ws)
        create_accessor_methods(attrs_hash)
      end

      # TODO: should add checks we're not overriding existing methods... can't
      # remember if it errors...
      #
      def create_accessor_methods(hash)
        hash.each do |name, attr_value|
          self.define_singleton_method(name) { attr_value }
        end
      end
    end
  end
end
