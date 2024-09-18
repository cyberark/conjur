module Util
  module V2Helpers
    def self.translate_kind(kind)
      case kind 
      when 'host'
        kind = 'workload'
      when 'variable'
        kind = 'secret'
      end
      kind
    end
  end
end
