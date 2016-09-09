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
        role.grant_to admin_role(account), admin_option: true
        ::Resource.create resource_id: bootstrap_policy_id(account), owner: admin_role(account)
      end

      def admin_role account
        ::Role["#{account}:user:admin"] or raise IndexError, "#{account}:user:admin"
      end

      def create orchestrator, obj
        cls = Types.const_get obj.class.name.split("::")[-1]
        cls.new orchestrator, obj
      end
    end

    class Base
      extend Forwardable

      def_delegators :@orchestrator, :handle_password, :handle_public_key

      attr_reader :orchestrator, :policy_object

      def initialize orchestrator, policy_object
        @orchestrator = orchestrator
        @policy_object = policy_object
      end

      def respond_to? sym
        super || @policy_object.respond_to?(sym)
      end

      def method_missing sym, *args, &block
        if @policy_object.respond_to?(sym)
          return @policy_object.send sym, *args, &block
        end

        super
      end
    end

    module CreateBase
      def owner_role
        ::Role[owner.roleid] or raise IndexError, owner.roleid
      end
    end

    module CreateRole
      def create_role!
        role = ::Role.create role_id: roleid
        role.grant_to owner_role, admin_option: true
      end
      
      def role
        ::Role[roleid]
      end
    end

    module CreateResource
      include CreateBase

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
      def create!
        super
        
        if password = ENV["CONJUR_PASSWORD_#{id.gsub(/[^a-zA-Z0-9]/, '_').upcase}"]
          handle_password role.id, password
        end
        
        Array(public_keys).each do |public_key|
          key_name = PublicKey.key_name public_key

          resourceid = [ account, "public_key", "#{self.role_kind}/#{self.id}/#{key_name}" ].join(":")
          (::Resource[resourceid] || ::Resource.create(resource_id: resourceid, owner: (::Role[owner.roleid] or raise IndexError, owner.roleid))).tap do |resource|
            handle_public_key resource.id, public_key
          end
        end
      end
    end
    
    class Variable < Record
      include CreateResource
      
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
      def create!
        Array(roles).each do |r|
          Array(members).each do |m|
            role = ::Role[r.roleid] or raise IndexError, r.roleid
            member = ::Role[m.role.roleid] or raise IndexError, m.role.roleid
            role.grant_to member, admin_option: m.admin
          end
        end
      end
    end

    class Permit < Types::Base
      def create!
        Array(resources).each do |r|
          Array(privileges).each do |p|
            Array(roles).each do |m|
              resource = ::Resource[r.resourceid] or raise IndexError, r.resourceid
              member = ::Role[m.roleid] or raise IndexError, m.roleid
              resource.permit p, member
            end
          end
        end
      end
    end
    
    class Policy < Types::Base
      def create!
        Types.create(orchestrator, self.role).create!
        Types.create(orchestrator, self.resource).create!
        
        Array(body).map(&:create!)
      end
    end
  end
end