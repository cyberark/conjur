module Conjur
  module PolicyParser
    module Types
      class YAMLList < Array
        def tag
          [ "!", self.class.name.split("::")[-1].underscore ].join
        end

        def encode_with coder
          coder.represent_seq tag, self
        end
      end

      module Tagless
        def tag; nil; end
      end

      module CustomStatement
        def custom_statement handler, &block
          record = yield
          class << record
            include RecordReferenceFactory
          end
          push record
          do_scope record, &handler
        end
      end

      module Grants
        include CustomStatement

        def grant &block
          custom_statement(block) do
            Conjur::PolicyParser::Types::Grant.new
          end
        end

        def revoke &block
          custom_statement(block) do
            Conjur::PolicyParser::Types::Revoke.new
          end
        end
      end

      module Permissions
        include CustomStatement

        def permit privilege, &block
          custom_statement(block) do
            Conjur::PolicyParser::Types::Permit.new(privilege)
          end
        end

        def give &block
          custom_statement(block) do
            Conjur::PolicyParser::Types::Give.new
          end
        end

        def retire &block
          custom_statement(block) do
            Conjur::PolicyParser::Types::Retire.new
          end
        end
      end

      # Entitlements will allow creation of any record, as well as declaration
      # of permit, deny, grant and revoke.
      class Entitlements < YAMLList
        include Tagless
        include Grants
        include Permissions

        def policy id=nil, &block
          policy = Policy.new
          policy.id(id) unless id.nil?
          push policy

          do_scope policy, &block
        end
      end

      class Body < YAMLList
        include Grants
        include Permissions
      end

      class Template < YAMLList
        include Grants
        include Permissions
      end

      # Policy includes the functionality of Entitlements, wrapped in a
      # policy role, policy resource, policy id and policy version.
      class Policy < Record
        include ActsAsResource
        include ActsAsRole

        def role
          raise "account is nil" unless account
          @role ||= Role.new("#{account}:policy:#{id}")
        end

        def resource
          raise "account is nil" unless account
          @resource ||= Resource.new("#{account}:policy:#{id}").tap do |resource|
            resource.owner = Role.new(owner.roleid)
            resource.annotations = annotations
          end
        end

        # Body is handled specially.
        def referenced_records
          super - Array(@body)
        end

        def body &block
          if block_given?
            singleton :body, lambda { Body.new }, &block
          end
          @body ||= []
        end

        def body= body
          @body = body
        end

        protected

        def singleton id, factory, &block
          object = instance_variable_get("@#{id}")
          unless object
            object = factory.call
            class << object
              include Tagless
            end
            instance_variable_set("@#{id}", object)
          end
          do_scope object, &block
        end
      end
    end
  end
end
