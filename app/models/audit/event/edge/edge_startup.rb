# frozen_string_literal: true

module Audit
  module Event
    class EdgeStartup < EdgeInstallBase
      def message_id
        "installed"
      end

      def operation
        "install"
      end

      def success_message
        "Edge instance #{@edge_name} has been installed"
      end

      def failure_message
        "Edge instance #{@edge_name} install failed"
      end

    end
  end
end