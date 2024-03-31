# frozen_string_literal: true
require_relative 'synchronizer_install_base'

module Audit
  module Event

    class TokenGeneration < SynchronizerInstallBase
      def message_id
        "creds-generated"
      end

      def operation
        "create"
      end

      def success_message
        "User #{@user} successfully generated installation token for Synchronizer named #{@synchronizer_id}"
      end

      def failure_message
        "User #{@user} failed to generate token for Synchronizer instance #{@synchronizer_id}"
      end
    end

  end
end


