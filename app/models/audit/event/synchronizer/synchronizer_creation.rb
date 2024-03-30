# frozen_string_literal: true
require_relative 'synchronizer_install_base'

module Audit
  module Event
    class SynchronizerCreation < SynchronizerInstallBase
      def message_id
        "created"
      end

      def operation
        "create"
      end

      def success_message
        "User #{@user} successfully created new Synchronizer instance"
      end

      def failure_message
        "User #{@user} failed to create new Synchronizer instance"
      end

    end

  end
end

