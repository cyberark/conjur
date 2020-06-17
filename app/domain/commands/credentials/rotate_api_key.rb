# frozen_string_literal: true

require 'command_class'

module Commands
  module Credentials

    # In might seem unnecessary to move this behavior into a command class.
    # However, we factor this out now to prepare for A) adding audit decorations
    # to this operation, and B) those audit events including the requestor's
    # client IP address, which will be an input to this CommandClass, rather than
    # to the Credential model's method.
    RotateApiKey ||= CommandClass.new(
      dependencies: {},
      inputs: %i(role)
    ) do

      def call
        rotate_api_key
      end

      private

      def rotate_api_key
        credentials.rotate_api_key
        credentials.save
      end

      def credentials
        @role.credentials
      end
    end
  end
end
