module DB
  module Repository
    class RoleRepository
      def initialize(annotation: ::Annotation, role: ::Role)
        @annotation = annotation
        @role = role
      end

      def find(account:, identifier:, name: nil, type: 'user')
        role = find_by_id(account: account, identifier: identifier, type: type)
        if role.blank? && name.present?
          role = find_by_annotation(account: account, identifier: identifier, type: type, name: name)
        end
        role
      end

      def find_by_id(account:, identifier:, type: 'user')
        @role[[account, type, identifier].join(':')]
      end

      def find_by_annotation(account:, identifier:, name:, type: 'user')
        resource_id = @annotation.find_annotation(
          account: account,
          identifier: identifier,
          name: name,
          type: 'user'
        ).try(:resource_id)

        return nil unless resource_id

        @role[role_id: resource_id]
      end
    end
  end
end
