module RolesHandler

  def parse_role_id(role_id, v2_syntax: false)
    if role_id.nil? || role_id.count(':') < 2
      raise Exceptions::InvalidRoleId, role_id
    end

    account, _, rest = role_id.partition(':')
    type, _, id = rest.partition(':')

    type = Util::V2Helpers.translate_kind(type) if v2_syntax

    { account: account, type: type, id: id }
  end
end
