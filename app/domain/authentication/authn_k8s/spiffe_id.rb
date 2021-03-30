module Authentication
  module AuthnK8s
    class SpiffeId

      def initialize(spiffe_id)
        @spiffe_id = spiffe_id
      end

      def namespace
        parsed[2]
      end

      def name
        parsed.last
      end

      def to_s
        @spiffe_id
      end

      def to_altname
        "URI:#{@spiffe_id}"
      end

      private

      def parsed
        @parsed ||= URI.parse(@spiffe_id).path.split('/')
      end
    end
  end
end
