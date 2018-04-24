require 'forwardable'
require 'types'

module Authentication
  class Webservices
    include Enumerable
    extend Forwardable

    TYPE = Types.Array(Types.Instance(Webservice))
    def_delegators :@arr, :each

    def initialize(arr)
      @arr = TYPE[arr]
    end

    def self.from_string(account, csv_string)
      csv_string
        .split(',')
        .map(&:strip)
        .map { |ws| Webservice.from_string(account, ws) }
    end
  end
end
