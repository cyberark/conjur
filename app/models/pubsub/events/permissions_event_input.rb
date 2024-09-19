# frozen_string_literal: true

class PermissionEventInput < EventInput
  include ResourcesHandler
  include RolesHandler

  CREATED = :create
  DELETED = :delete

  INPUTS = {
    CREATED => { event_op: 'created', data: Struct.new(:branch, :name, :permission, keyword_init: true) }.freeze,
    DELETED => { event_op: 'deleted', data: Struct.new(:branch, :name, :permission, keyword_init: true) }.freeze
  }.freeze

  def get_event_input(operation, db_obj)
    input = INPUTS[operation]
    branch, name, @resource_type = parse_resource_id(db_obj.resource_id, v2_syntax: true).values_at(:branch, :name, :type)
    kind, id = parse_role_id(db_obj.role_id, v2_syntax: true).values_at(:type, :id)

    # This line must come after @resource_type is set
    event_type = get_event_type(input[:event_op])

    subject = { kind: kind, id: id }
    permission = { subject: subject, privilege: db_obj.privilege }

    event_data = {}
    event_data[:data] = input[:data].new(branch: branch, name: name, permission: permission)
    event_data[:specversion] = "1.0"

    event_value = event_data.to_json
    [event_type, event_value]
  end

  protected

  def get_entity_type
    "#{@resource_type}.permission"
  end
end
