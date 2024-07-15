# frozen_string_literal: true

class SecretEventInput < EventInput
  EventData = Struct.new(:specversion, :branch, :name, :version, :value, keyword_init: true) do
    def initialize(specversion:, branch:, name:, version: nil, value: nil)
      super
    end
  end

  def get_event_input(operation, db_obj)
    branch, _, name = db_obj.resource_id.rpartition(':')[2].rpartition('/')
    case operation
    when :"value.changed"
      event_type = get_event_type(operation)
      event_value = EventData.new(
        specversion: '1.0',
        branch: branch,
        name: name,
        version: db_obj.version.to_i
      ).to_h.to_json
      [event_type, event_value]
    else
      [nil, nil]
    end
  end

  protected

  def get_entity_type
    'secret'
  end
end

