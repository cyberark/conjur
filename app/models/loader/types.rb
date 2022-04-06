# frozen_string_literal: true

module Loader
  module Types
    class << self
      def find_or_create_root_policy(account)
        ::Resource[root_policy_id(account)] || create_root_policy(account)
      end

      def root_policy_id(account)
        "#{account}:policy:root"
      end

      def create_root_policy(account)
        role = ::Role.create(role_id: root_policy_id(account))
        ::Resource.create(resource_id: root_policy_id(account), owner: admin_role(account))
      end

      def admin_role account
        ::Role["#{account}:user:admin"] || raise(Exceptions::RecordNotFound, "#{account}:user:admin")
      end

      # Wraps a policy object with a corresponding +Loader::Types+ object.
      #
      # +external_handler+ should provide the methods +policy_id+, +handle_password+,
      # +handle_public_key+. This argument is optional if the policy will not use
      # that functionality.
      def wrap obj, external_handler = nil
        cls = Types.const_get(obj.class.name.split("::")[-1])
        cls.new(obj, external_handler)
      end
    end

    class Base
      extend Forwardable

      def_delegators :@external_handler, :policy_id, :handle_password, :handle_public_key, :handle_restricted_to
      def_delegators :@policy_object, :owner, :id

      attr_reader :policy_object, :external_handler

      def initialize policy_object, external_handler = nil
        @policy_object = policy_object
        @external_handler = external_handler
      end

      def find_ownerid
        find_roleid(owner.roleid)
      end

      def find_roleid id
        (::Role[id] || public_roles_model[id]).try(:role_id) || raise(Exceptions::RecordNotFound, id)
      end

      def find_resourceid id
        (::Resource[id] || public_resources_model[id]).try(:resource_id) || raise(Exceptions::RecordNotFound, id)
      end

      protected

      def public_roles_model
        external_handler.model_for_table(:roles)
      end

      def public_resources_model
        external_handler.model_for_table(:resources)
      end
    end

    module CreateRole
      def self.included base
        base.module_eval do
          def_delegators(:@policy_object, :roleid)
        end
      end

      def create_role!
        ::Role.create(role_id: roleid)
      end

      def role
        ::Role[roleid]
      end
    end

    module CreateResource
      def self.included base
        base.module_eval do
          def_delegators(:@policy_object, :resourceid, :annotations, :annotations=)
        end
      end

      def create_resource!
        ::Resource.create(resource_id: resourceid, owner_id: find_ownerid).tap do |resource|
          records = Hash(annotations).map { |name, value| [resource.id, name, value.to_s]}
          resource.annotations_dataset.import(%i[resource_id name value], records)
        end
      end

      def resource
        ::Resource[resourceid]
      end
    end

    class Record < Types::Base
      include CreateRole
      include CreateResource

      def verify
        message = "Verify method for entity #{self} does not exist"
        raise Exceptions::InvalidPolicyObject.new(self.id, message: message)
      end

      def calculate_defaults!; end

      def create!
        verify
        calculate_defaults!
        create_role! if policy_object.respond_to?(:roleid)
        create_resource! if policy_object.respond_to?(:resourceid)
      end
    end

    class Role < Record
      def verify; end
    end

    class Resource < Record
      def verify; end
    end

    class Layer < Record
      def verify; end
    end

    class Host < Record
      def verify; end
      def_delegators :@policy_object, :restricted_to

      def create!
        self.handle_restricted_to(self.roleid, restricted_to)
        super
      end
    end

    class HostFactory < Record
      def_delegators :@policy_object, :layers

      def verify; end

      def create!
        super

        layer_roleids.each do |layerid|
          ::RoleMembership.create(
            role_id: layerid,
            member_id: self.roleid,
            admin_option: false,
            ownership: false
          )
        end
      end

      protected

      def layer_roleids
        verify_layers_exist!

        Array(self.layers).map do |layer|
          find_roleid(layer.roleid)
        end
      end

      def verify_layers_exist!
        if self.layers.nil?
          message = "Host factory '#{identifier}' does not include any layers"
          raise Exceptions::InvalidPolicyObject.new(self.id, message: message)
        end
      end

      def identifier
        self.roleid.split(':', 3)[2]
      end
    end

    class Group < Record
      def_delegators :@policy_object, :gidnumber

      def verify; end

      def create!
        self.annotations ||= {}
        self.annotations["conjur/gidnumber"] ||= self.gidnumber if self.gidnumber

        super
      end
    end

    class User < Record
      def_delegators :@policy_object, :public_keys, :account, :role_kind, :uidnumber, :restricted_to

      # Below is a sample method verifying policy data validity
      def verify
        #  if self.uidnumber == 8
        #  message = "User '#{self.id}' has wrong params"
        #  raise Exceptions::InvalidPolicyObject.new(self.id, message: message)
        # end
      end

      # Below is a sample method filling defaults for User entity in policy
      # def calculate_defaults!
      #  if self.uidnumber == nil
      #    self.annotations["conjur/uidnumber"] = 10
      #  end
      # end

      def create!
        self.annotations ||= {}
        self.annotations["conjur/uidnumber"] ||= self.uidnumber if self.uidnumber

        super

        if password = ENV["CONJUR_PASSWORD_#{id.gsub(/[^a-zA-Z0-9]/, '_').upcase}"]
          handle_password(role.id, password)
        end

        Array(public_keys).each do |public_key|
          key_name = PublicKey.key_name(public_key)

          resourceid = [ account, "public_key", "#{self.role_kind}/#{self.id}/#{key_name}" ].join(":")
          (::Resource[resourceid] || ::Resource.create(resource_id: resourceid, owner_id: find_ownerid)).tap do |resource|
            handle_public_key(resource.id, public_key)
          end
        end

        handle_restricted_to(self.roleid, restricted_to)
      end
    end

    class Variable < Record
      include CreateResource

      def_delegators :@policy_object, :kind, :mime_type

      def verify; end

      def create!
        self.annotations ||= {}
        self.annotations["conjur/kind"] ||= self.kind if self.kind
        self.annotations["conjur/mime_type"] ||= self.mime_type if self.mime_type

        super
      end
    end

    class Webservice < Record
      include CreateResource

      def verify; end

    end

    class Grant < Types::Base
      def_delegators :@policy_object, :roles, :members

      def create!
        Array(roles).each do |r|
          Array(members).each do |m|
            ::RoleMembership.create(
              role_id: find_roleid(r.roleid),
              member_id: find_roleid(m.role.roleid),
              admin_option: m.admin,
              ownership: false
            )
          end
        end
      end
    end

    class Permit < Types::Base
      def_delegators :@policy_object, :resources, :privileges, :roles

      def create!
        Array(resources).each do |r|
          Array(privileges).each do |p|
            Array(roles).each do |m|
              ::Permission.create(
                resource_id: find_resourceid(r.resourceid),
                privilege: p,
                role_id: find_roleid(m.roleid)
              )
            end
          end
        end
      end
    end

    class Policy < Types::Base
      def_delegators :@policy_object, :role, :resource, :body

      def create!
        Types.wrap(self.role, external_handler).create!
        Types.wrap(self.resource, external_handler).create!

        Array(body).map(&:create!)
      end
    end

    # Deletions

    class Deletion < Types::Base
    end

    class Deny < Deletion
      def delete!
        permission = ::Permission[role_id: policy_object.role.roleid, privilege: policy_object.privilege, resource_id: policy_object.resource.resourceid, policy_id: policy_id]
        permission.destroy if permission
      end
    end

    class Revoke < Deletion
      def delete!
        membership = ::RoleMembership[role_id: policy_object.role.roleid, member_id: policy_object.member.roleid, policy_id: policy_id]
        membership.destroy if membership
      end
    end

    class Delete < Deletion
      def delete!
        if policy_object.record.respond_to?(:resourceid)
          resource = ::Resource[policy_object.record.resourceid]
          resource.destroy if resource
        end
        if policy_object.record.respond_to?(:roleid)
          role = ::Role[policy_object.record.roleid]
          role.destroy if role
        end
      end
    end
  end
end
