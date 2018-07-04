# frozen_string_literal: true

require 'English'

module Audit
  class Event
    module CanFail
      def message
        if success
          success_message
        else
          [failure_message, error_message].compact.join(': ')
        end
      end
      
      def structured_data 
        super.deep_merge SDID::ACTION => { result: success_text }
      end
      
      def severity
        success ? Syslog::LOG_INFO : Syslog::LOG_WARNING
      end

      def self.included other
        other.class_eval do
          field success: true, error_message: nil
          abstract_field :success_message, :failure_message
          extend CanFail::ClassMethods
        end
      end

      module ClassMethods
        # Automatically initialize an instance with data from currently handled
        # exception (if any).
        def new_with_exception **parameters
          if $ERROR_INFO
            new({ success: false, error_message: $ERROR_INFO.message }.merge(parameters))
          else
            new({ success: true }.merge(parameters))
          end
        end
      end

      protected

      def success_text
        success ? 'success' : 'failure'
      end
    end
  end
end
