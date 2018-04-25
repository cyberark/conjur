# A simple factory for creating custom RuntimeError classes without
# the typical boilerplate
#
class ErrorClass
  def self.new(msg)
    Class.new(RuntimeError) do
      def initialize(*args)
        @args = args
      end
      define_method(:to_s) do
        @args.each.with_index.reduce(msg) do |m,(x,i)|
          m.gsub(Regexp.new("\\{#{i}}"), x)
        end
      end
    end
  end
end
