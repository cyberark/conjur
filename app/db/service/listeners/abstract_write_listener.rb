# frozen_string_literal: true
require 'singleton'

module DB
  module Service
    module Listeners

      # Listeners for DB change
      class AbstractWriteListener
          include Singleton
          def notify(entity, operation, db_obj)
            raise NotImplementedError
          end
        end
    end
  end
end