# frozen_string_literal: true

Sequel.split_symbols = true
Sequel.extension(:core_extensions, :postgres_schemata)
Sequel::Model.plugin(:validation_helpers)

class Sequel::Model
  def write_id_to_json response, field
    value = response.delete("#{field}_id")
    response[field] = value if value
  end
end
