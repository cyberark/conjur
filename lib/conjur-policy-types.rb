module Conjur
  module Policy
    module Types
      module CreateBase
        def owner_role
          ::Role[owner.roleid] or raise IndexError, owner.roleid
        end
      end

      module CreateRole
        include CreateBase

        def create_role!
          ::Role.create role_id: roleid
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
              resource.add_annotation name: name, value: value
            end
          end
        end
        
        def resource
          ::Resource[resourceid]
        end
      end
        
      class Record
        include CreateRole
        include CreateResource
        
        def create!
          create_role! if respond_to?(:roleid)
          create_resource! if respond_to?(:resourceid)
        end
      end
      
      class Layer < Record
      end

      class Group < Record
      end
      
      class User < Record
        def create!
          super
          
          if password = ENV["CONJUR_PASSWORD_#{id.gsub(/[^a-zA-Z0-9]/, '_').upcase}"]
            $stderr.puts "Setting password for '#{roleid}'"
            role.password = password
          end
          
          Array(public_keys).each do |public_key|
            key_name = PublicKey.key_name public_key

            resourceid = [ self.account, "public_key", "#{self.role_kind}/#{self.id}/#{key_name}" ].join(":")
            (::Resource[resourceid] || ::Resource.create(resource_id: resourceid, owner: (::Role[owner.roleid] or raise IndexError, owner.roleid))).tap do |resource|
              unless resource.secrets.last && resource.secrets.last.value == public_key
                ::Secret.create resource: resource, value: public_key
              end
            end
          end
        end
      end
      
      class Variable
        include CreateResource
        
        def create!
          self.annotations ||= {}
          self.annotations["conjur/kind"] ||= self.kind if self.kind
          self.annotations["conjur/mime_type"] ||= self.mime_type if self.mime_type
          
          super
        end
      end
      
      class Webservice
        include CreateResource
      end
      
      class Grant
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

      class Permit
        def create!
          Array(resources).each do |r|
            Array(privileges).each do |p|
              Array(roles).each do |m|
                resource = ::Resource[r.resourceid] or raise IndexError, r.resourceid
                member = ::Role[m.role.roleid] or raise IndexError, m.role.roleid
                resource.permit p, member
              end
            end
          end
        end
      end
      
      class Policy
        def create!
          self.role.create!
          self.resource.create!
          
          Array(body).map(&:create!)
        end
      end
    end
  end
end
