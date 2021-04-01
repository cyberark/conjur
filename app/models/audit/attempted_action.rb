module Audit
  module Event
    # The refactoring to improve this involves making 3 classes here instead of
    # one -- Failure and Success classes without any conditionals, and an
    # outer class like this one to delegate to them.  This makes the code less
    # readable overall: abstraction cost can exceed duplication cost.
    # :reek:RepeatedConditional
    class AttemptedAction

      def initialize(success:, operation:)
        @success = success
        @operation = operation
      end

      # Why do we need both failure_msg and error_msg?
      # failure_msg: Any reason the attempt failed.  Eg, user not authorized.
      # error_msg: A ruby error occurred while processing.
      def message(success_msg:, failure_msg:, error_msg: nil)
        return success_msg if @success

        [failure_msg, error_msg].compact.join(': ')
      end

      # action_sd means "action structured data"
      def action_sd
        { SDID::ACTION => { result: success_text, operation: @operation } }
      end

      def severity
        @success ? Syslog::LOG_INFO : Syslog::LOG_WARNING
      end

      def success_text
        @success ? 'success' : 'failure'
      end
    end
  end
end
