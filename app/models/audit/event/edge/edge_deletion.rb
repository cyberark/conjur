# frozen_string_literal: true
require_relative 'edge_install_base'

module Audit
  module Event
    class EdgeDeletion < EdgeInstallBase
      def message_id
        "deleted"
      end

      def operation
        "delete"
      end

      def success_message
        "User #{@user} successfully deleted Edge instance named #{@edge_name}"
      end

      def failure_message
        "User #{@user} failed to delete Edge instance named #{@edge_name}"
      end
    end
  end
end
