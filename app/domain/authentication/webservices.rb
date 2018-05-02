require 'forwardable'

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
      # NOTE: This is needed, eg, in the case the CONJUR_AUTHENTICATORS
      #       is not defined
      return Webservices.new([]) unless csv_string

      Webservices.new(
        csv_string
        .split(',')
        .map(&:strip)
        .map { |ws| Webservice.from_string(account, ws) }
      )
    end
  end
end
