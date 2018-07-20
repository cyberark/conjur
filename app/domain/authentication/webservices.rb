# frozen_string_literal: true

# This is here to fix a double-loading bug that occurs only in openshift and
# K8s tests.  We don't fully understand what causes the bug but this is the
# hack we settled on to fix it.
#
if defined? Authentication::Webservices
  return
end

require 'forwardable'

module Authentication
  class Webservices
    include Enumerable
    extend Forwardable

    TYPE = ::Types.Array(::Types.Instance(::Authentication::Webservice))
    def_delegators :@arr, :each

    def initialize(arr)
      @arr = TYPE[arr]
    end

    def self.from_string(account, csv_string)
      ::Types::NonEmptyString[csv_string] # validate non-empty

      self.new(
        csv_string
          .split(',')
          .map(&:strip)
          .map { |ws| ::Authentication::Webservice.from_string(account, ws) }
      )
    end
  end
end
