module Util
  def self.validate_data(data, data_fields, params_count)
    data_fields.each do |field_symbol, field_type|
      # The field exists in data
      if data[field_symbol].nil?
        raise Errors::Conjur::ParameterMissing.new(field_symbol.to_s)
      end

      # The field is of correct type
      unless data[field_symbol].is_a?(field_type)
        raise Errors::Conjur::ParameterTypeInvalid.new(field_symbol.to_s, field_type.to_s)
      end

      # The field value is not empty
      if data[field_symbol].empty?
        raise Errors::Conjur::ParameterMissing.new(field_symbol.to_s)
      end
    end

    # We don't have more fields then expected
    if data.keys.count != params_count
      raise Errors::Conjur::NumOfParametersInvalid.new(data_fields.keys.join(", "))
    end
  end
end