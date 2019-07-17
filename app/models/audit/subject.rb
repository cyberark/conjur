# frozen_string_literal: true

require 'util/struct'

module Audit
  class Subject < Util::Struct
    abstract_field :to_h, :to_s

    class Annotation < Subject
      field :name, :resource_id
      to_h {{ annotation: name, resource: resource_id }}
      to_s { format "annotation %s on %s", name, resource_id }
    end

    class Permission < Subject
      field :resource_id, :role_id, :privilege
      to_h {{ resource: resource_id, role: role_id, privilege: privilege }}
      to_s { format "permission of %s to %s on %s", role_id, privilege, resource_id }
    end

    class Resource < Subject
      field :resource_id
      to_h {{ resource: resource_id }}
      to_s { format "resource %s", resource_id }
    end

    class Role < Subject
      field :role_id
      to_h {{ role: role_id }}
      to_s { format "role %s", role_id }
    end

    class RoleMembership < Subject
      field :role_id, :member_id, :ownership
      to_h {{ role: role_id, type => member_id }}
      to_s { format "%sship of %s in %s", type, member_id, role_id }

      def type
        ownership == 't' ? :owner : :member
      end
    end

    class PolicyFactory < Subject
      field :role_id
      to_h {{ role: role_id }}
      to_s { format "policy_factory %s", role_id }
    end
  end
end
