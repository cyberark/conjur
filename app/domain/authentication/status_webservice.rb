# frozen_string_literal: true

# This is here to fix a double-loading bug that occurs only in openshift and
# K8s tests.  We don't fully understand what causes the bug but this is the
# hack we settled on to fix it.

if defined? Authentication::StatusWebservice
  return
end

require 'dry-struct'
require 'types'

module Authentication
  class StatusWebservice < ::Dry::Struct
    constructor_type :schema

      attribute :parent_name, ::Types::NonEmptyString
      attribute :parent_resource_id, ::Types::NonEmptyString
      attribute :resource_class, (::Types::Any.default { ::Resource })

      def name
        "#{parent_name}/status"
      end

      def resource_id
        "#{resource_id}/status"
      end

      def resource
        @status_resource ||= resource_class[resource_id]
      end

      def annotation(name)
        resource&.annotation(name)
      end
    end
  end
