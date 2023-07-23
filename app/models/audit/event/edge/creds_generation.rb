# frozen_string_literal: true
require_relative 'edge_install_base'

module Audit
  module Event
    class CredsGeneration < EdgeInstallBase
      def message_id
        "creds-generated"
      end

      def operation
        "create"
      end

      def success_message
        "User #{@user} successfully generated installation token for Edge named #{@edge_name}"
      end

      def failure_message
        "User #{@user} failed to generate token for Edge instance #{@edge_name}"
      end

    end
  end
end