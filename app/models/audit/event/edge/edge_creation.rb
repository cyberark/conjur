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
        "User #{@user} successfully created new Edge instance named #{@edge_name}"
      end

      def failure_message
        "User #{@user} failed to create new Edge instance named #{@edge_name}"
      end
    end
  end
end
