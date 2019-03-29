# frozen_string_literal: true

require 'dry-struct'

module CA
  # Facade for a Variable Conjur resource
  class Variable < Dry::Struct
    attribute :resource, Types.Definition(Resource)

    # :reek:NilCheck
    def value
      resource&.secret&.value 
    end    
  end
end
