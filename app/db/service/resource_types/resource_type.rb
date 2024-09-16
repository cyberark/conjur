# frozen_string_literal: true
require 'singleton'

module DB
  module Service
    module Types
      class ResourceType
        include Singleton

        def create(resource)
          raise NotImplementedError
        end

        def delete(resource)
          raise NotImplementedError
        end
      end
    end
  end
end
