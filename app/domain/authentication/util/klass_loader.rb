# frozen_string_literal: true

module Authentication
  module Util

    # This is a utility to handle detection of Authenticator and Role Annotation
    # validations. This enables us to optionally add validations for a particular
    # authenticator.
    #
    # It returns either the provided block or nil.
    class KlassLoader
      class << self
        def set_if_present(&block)
          block.call
        rescue NameError
          nil
        end
      end
    end
  end
end
