module Rotation

    class Resource
      attr_reader :id

      def initialize(resource_id)
        @id = resource_id
      end

      def account
        @id.split(':')[0]
      end

      def kind
        @id.split(':')[1]
      end

      def name
        @id.split(':', 3)[2]
      end

      # def renamed(name)
      #   self.class.new("#{account}:#{kind}:#{name}")
      # end

      def sibling(name)
        prefix = @id.match(%r{(.*)/.*})[1]
        self.class.new("#{prefix}/name")
      end
    end

end
