module Rotation
  module Rotators
    module Example

      class ExampleRotator

        def initialize
          @cnt = 0
        end

        def required_variables
          # you could do a case statment and return different requirements
          # depending on the annotated variable...
          # 
          # at the end of the day, you just return an array of variable ids
          %w[rotate-10s rotate-15s]
        end

        def new_values(variable_values)
          p 'variable_values', variable_values
          # calc some new values however you want...
          # return them as a {variable_name: new_value} Hash
          #
          @cnt += 1
          variable_values.map do |var, val|
            [var, "#{var}-value-#{@cnt}"]
          end.to_h
        end
      end

    end
  end
end
