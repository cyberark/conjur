module Audit
  module Event
    class ComparableEvent
      def initialize(evt)
        @evt = evt
      end

      def ==(other)
        @evt.progname == other.progname &&
          @evt.severity == other.severity &&
          @evt.message == other.message &&
          @evt.message_id == other.message_id &&
          @evt.structured_data == other.structured_data &&
          @evt.facility == other.facility
      end
    end
  end
end
