# A CSR decorator that allows reading of the spiffe id and common name.
#
module Util
  module OpenSsl
    module X509
      class SmartSubject < SimpleDelegator

        def common_name
          parts['CN']
        end

        def common_name=(common_name)
          parts['CN'] = common_name
        end

        def to_s
          parts.map{|k, v| "#{k}=#{v}" }.join(',')
        end

        private

        # We have memoization so we can update the common_name
        def parts
          @parts ||= to_a.each(&:pop).to_h
        end
      end
    end
  end
end
