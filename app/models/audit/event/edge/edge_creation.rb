# frozen_string_literal: true
require_relative 'edge_install_base'

module Audit
  module Event
    class EdgeCreation < EdgeInstallBase
      def message_id
        "created"
      end

      def operation
        "created"
      end

      def success_message
        "edge instance #{@edge_name} has been created"
      end

      def failure_message
        "edge instance #{@edge_name} creation failed"
      end
    end
  end
end
