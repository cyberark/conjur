module Loader
  module Types
    class << self
      def find_or_create_bootstrap_policy account
        ::Resource[bootstrap_policy_id(account)] or create_bootstrap_policy account
      end

      def bootstrap_policy_id account
        "#{account}:policy:bootstrap"
      end

      def create_bootstrap_policy account
        role = ::Role.create role_id: bootstrap_policy_id(account)
        ::Resource.create resource_id: bootstrap_policy_id(account), owner: admin_role(account)
      end

      def admin_role account
        ::Role["#{account}:user:admin"] or raise Exceptions::RecordNotFound, "#{account}:user:admin"
      end

      def wrap orchestrator, obj
        cls = Types.const_get obj.class.name.split("::")[-1]
        cls.new orchestrator, obj
      end
    end

    class Base
      extend Forwardable

      def_delegators :@orchestrator, :handle_password, :handle_public_key
      def_delegators :@policy_object, :owner, :id

      attr_reader :orchestrator, :policy_object

      def initialize orchestrator, policy_object
        @orchestrator = orchestrator
        @policy_object = policy_object
      end

      def owner_role
        ::Role[owner.roleid] || ::Role.create(role_id: owner.roleid)
      end

      def find_role id, allow_foreign = false
        def foreign_role_exists? id
          !!Sequel::Model(:public__roles)[id]
        end
        def create_foreign_role id, allow_foreign
          ::Role.create(role_id: id) if allow_foreign && foreign_role_exists?(id)
        end

        ::Role[id] || create_foreign_role(id, allow_foreign) or raise Exceptions::RecordNotFound, id
      end
    end

    module CreateRole
      def self.included base
        base.module_eval do
          def_delegators :@policy_object, :roleid
        end
      end

      def create_role!
        ::Role.create role_id: roleid
      end
      
      def role
        ::Role[roleid]
      end
    end

    module CreateResource
      def self.included base
        base.module_eval do
          def_delegators :@policy_object, :resourceid, :annotations, :annotations=
        end
      end

      def create_resource!
        ::Resource.create(resource_id: resourceid, owner: owner_role).tap do |resource|
          Hash(annotations).each do |name, value|
            resource.add_annotation name: name, value: value.to_s
          end
        end
      end
      
      def resource
        ::Resource[resourceid]
      end
    end
      
    class Record < Types::Base
      include CreateRole
      include CreateResource
      
      def create!
        create_role! if policy_object.respond_to?(:roleid)
        create_resource! if policy_object.respond_to?(:resourceid)
      end
    end

    class Role < Record
    end

    class Resource < Record
    end

    class Layer < Record
    end

    class Host < Record
    end

    class Group < Record
    end
    
    class User < Record
      def_delegators :@policy_object, :public_keys, :account, :role_kind

      def create!
        super
        
        if password = ENV["CONJUR_PASSWORD_#{id.gsub(/[^a-zA-Z0-9]/, '_').upcase}"]
          handle_password role.id, password
        end
        
        Array(public_keys).each do |public_key|
          key_name = PublicKey.key_name public_key

          resourceid = [ account, "public_key", "#{self.role_kind}/#{self.id}/#{key_name}" ].join(":")
          (::Resource[resourceid] || ::Resource.create(resource_id: resourceid, owner: (::Role[owner.roleid] or raise Exceptions::RecordNotFound, owner.roleid))).tap do |resource|
            handle_public_key resource.id, public_key
          end
        end
      end
    end
    
    class Variable < Record
      include CreateResource

      def_delegators :@policy_object, :kind, :mime_type
      
      def create!
        self.annotations ||= {}
        self.annotations["conjur/kind"] ||= self.kind if self.kind
        self.annotations["conjur/mime_type"] ||= self.mime_type if self.mime_type
        
        super
      end
    end
    
    class Webservice < Record
      include CreateResource
    end
    
    class Grant < Types::Base
      def_delegators :@policy_object, :roles, :members

      def create!
        Array(roles).each do |r|
          Array(members).each do |m|
            find_role(r.roleid).grant_to find_role(m.role.roleid, allow_foreign = true), admin_option: m.admin
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
              resource = ::Resource[r.resourceid] or raise Exceptions::RecordNotFound, r.resourceid
              resource.permit p, find_role(m.roleid, allow_foreign = true)
            end
          end
        end
      end
    end
    
    class Policy < Types::Base
      def_delegators :@policy_object, :role, :resource, :body

      def create!
        Types.wrap(orchestrator, self.role).create!
        Types.wrap(orchestrator, self.resource).create!
        
        Array(body).map(&:create!)
      end
    end

    # Deletions

    class Deletion < Types::Base
      def policy_id
        orchestrator.policy_version.policy.id
      end
    end

    class Deny < Deletion
      def delete!
        permission = ::Permission[role_id: policy_object.role.id, privilege: policy_object.privilege, resource_id: policy_object.resource.id, policy_id: policy_id]
        permission.destroy if permission
      end
    end

    class Revoke < Deletion
      def delete!
        membership = ::RoleMembership[role_id: policy_object.role.id, member_id: policy_object.member.id, policy_id: policy_id]
        membership.destroy if membership
      end
    end

    class Delete < Deletion
      def delete!
        resource = ::Resource[policy_object.record.id]
        resource.destroy if resource
        role = ::Role[policy_object.record.id]
        role.destroy if role
      end
    end
  end
end
