# frozen_string_literal: true

require './app/domain/resources/resources_handler'

class SecretEventInput < EventInput
  include ResourcesHandler
  include RolesHandler

  CREATE = :create
  DELETE = :delete
  CHANGE = :change

  INPUTS = {
    CREATE => {event_op: 'created', data: Struct.new( :branch, :name, :owner, keyword_init: true)},
    DELETE => {event_op: 'deleted', data: Struct.new( :branch, :name, keyword_init: true)},
    CHANGE => {event_op: 'value.changed', data: Struct.new( :branch, :name, :version, keyword_init: true)}
  }

  def get_event_input(operation, db_obj)
    input = INPUTS[operation]
    event_type = get_event_type(input[:event_op])

    branch, name = parse_resource_id(db_obj.resource_id).values_at(:branch, :name)
    data = input[:data]
    args = { branch: branch,
             name: name }

    args[:version] = db_obj.version.to_i if data.members.include?(:version)

    if data.members.include?(:owner)
      kind, id = parse_role_id(db_obj[:owner_id], v2_syntax: true).values_at(:type, :id)
      args[:owner] = { kind: kind, id: id }
    end
    dict = {}
    dict[:data] = data.new(args).to_h
    dict[:specversion] = "1.0"
    event_value = dict.to_json

    [event_type, event_value]
  end

  protected

  def get_entity_type
    'secret'
  end
end

