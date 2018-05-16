module Rotation
  module Rotators
    module Example

      class ExampleRotator

        def required_variables(annotated_variable)
          # you could do a case statment and return different requirements
          # depending on the annotated variable...
          # 
          # at the end of the day, you just return an array of variable ids
          %w[aws:region aws:access_key_id]
        end

        def rotate(variable_values)
          # calc some new values however you want...
          # return them as a hash
          {
            'aws:access_key_id': 'new key',
            'aws:secret_access_key': 'new secret'
          }
        end
      end

    end
  end
end
