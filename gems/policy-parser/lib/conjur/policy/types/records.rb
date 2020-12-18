module Conjur
  module PolicyParser
    module Types
      # A createable record type.
      class Record < Base
        def role?
          false
        end

        def resource?
          false
        end

        def subject_id
          id
        end
      end
      
      module ActsAsResource
        def self.included(base)
          base.module_eval do
            attribute(:id,   kind: :string, singular: true, dsl_accessor: true)
            attribute(:account, kind: :string, singular: true)
            attribute(:owner, kind: :role, singular: true, dsl_accessor: true)
            
            attribute(:annotations, kind: :hash, type: Hash, singular: true)
            
            def description value
              annotation('description', value)
            end
            
            def annotation name, value
              self.annotations ||= {}
              self.annotations[name] = value
            end
          end
        end
        
        def initialize id = nil
          self.id = id if id
        end
        
        def to_s
          "#{resource_kind.gsub('_', ' ')} '#{id}'#{account && account != Conjur.configuration.account ? " in account '#{account}'": ''}"
        end
        
        def resourceid default_account = nil
          [ account || default_account, resource_kind, id ].join(":")
        end
        
        def resource_kind
          self.class.name.split("::")[-1].underscore
        end

        def resource_id
          id
        end
        
        def action
          :create
        end
        
        def resource?
          true
        end
        
        def immutable_attribute_names
          []
        end

      end
      
      module ActsAsRole
        def roleid default_account = nil
          [ account || default_account, role_kind, id ].join(":")
        end
        
        def role?
          true
        end
        
        def role_kind
          self.class.name.split("::")[-1].underscore
        end
        
        def role_id
          id
        end
      end
      
      module ActsAsCompoundId
        def initialize kind_or_id = nil, id_or_options = nil
          if kind_or_id && id_or_options && id_or_options.is_a?(String)
            self.kind = kind_or_id
            self.id = id_or_options
          elsif kind_or_id&.index(":")
            id_or_options ||= {}
            account, self.kind, self.id = kind_or_id.split(':', 3)
            self.account = account if account != id_or_options[:default_account]
          end
        end

        def == other
          other.is_a?(ActsAsCompoundId) && kind == other.kind && id == other.id && account == other.account
        end

        def to_s
          "#{kind} #{self.class.short_name.underscore} '#{id}'#{account && account != Conjur.configuration.account ? " in account '#{account}'": ''}"
        end
      end
      
      class Role < Record
        include ActsAsRole
        include ActsAsCompoundId
        
        attribute :id,   kind: :string, singular: true, dsl_accessor: true
        attribute :kind, kind: :string, singular: true, dsl_accessor: true
        attribute :account, kind: :string, singular: true

        def roleid default_account = nil
          raise "account is required" unless account || default_account

          [ account || default_account, kind, id ].join(":")
        end
        
        def role_id 
          id 
        end

        def role_kind 
          kind 
        end
                  
        def immutable_attribute_names
          []
        end
      end
      
      class Resource < Record
        include ActsAsResource
        include ActsAsCompoundId

        attribute :kind, kind: :string, singular: true, dsl_accessor: true

        def resource_kind
          kind
        end
      end
      
      class User < Record
        include ActsAsResource
        include ActsAsRole

        attribute :uidnumber, kind: :integer, singular: true, dsl_accessor: true
        attribute :public_key, kind: :string, dsl_accessor: true
        attribute :restricted_to, kind: :cidr, dsl_accessor: true

        def id_attribute 
          'login' 
        end
        
        def custom_attribute_names
          %i[uidnumber public_key restricted_to]
        end
      end
      
      class Group < Record
        include ActsAsResource
        include ActsAsRole
        
        attribute :gidnumber, kind: :integer, singular: true, dsl_accessor: true

        def custom_attribute_names
          [ :gidnumber ]
        end
      end
      
      class Host < Record
        include ActsAsResource
        include ActsAsRole

        attribute :restricted_to, kind: :cidr, dsl_accessor: true

        def custom_attribute_names
          [ :restricted_to ]
        end
      end
      
      class Layer < Record
        include ActsAsResource
        include ActsAsRole
      end
      
      class Variable < Record
        include ActsAsResource
        
        attribute :kind,      kind: :string, singular: true, dsl_accessor: true
        attribute :mime_type, kind: :string, singular: true, dsl_accessor: true

        def custom_attribute_names
          %i[kind mime_type]
        end
        
        def immutable_attribute_names
          %i[kind mime_type]
        end
      end
      
      class Webservice < Record
        include ActsAsResource
      end
      
      class HostFactory < Record
        include ActsAsResource
        include ActsAsRole

        attribute :role, kind: :role, dsl_accessor: true, singular: true
        attribute :layer, kind: :layer, dsl_accessor: true
        
        alias role_accessor role
        
        def role *args
          if args.empty?
            role_accessor || owner
          else
            role_accessor(*args)
          end
        end
      end

      class PolicyFactory < Record
        include ActsAsResource
        include ActsAsRole

        attribute :role,     kind: :role,   singular: true, dsl_accessor: true
        attribute :base,     kind: :policy, singular: true, dsl_accessor: true

        alias role_accessor role

        def role *args
          if args.empty?
            role_accessor || self.owner
          else
            role_accessor(*args)
          end
        end

        # Don't include template records, these are pointers to
        # future records, not records in this policy
        def referenced_records
          super - Array(@template)
        end

        def template &block
          if block_given?
            singleton :template, lambda { Template.new }, &block
          end
          @template ||= []
        end

        def template= template
          @template = template
        end
      end

      class AutomaticRole < Base
        include ActsAsRole
        
        def initialize record = nil, role_name = nil
          self.record = record if record
          self.role_name = role_name if role_name
        end
        
        attribute :record,    kind: :role,   singular: true
        attribute :role_name, kind: :string, singular: true
        
        class << self
          def build fullid
            account, kind, id = fullid.split(':', 3)
            raise "Expecting @ for kind, got #{kind}" unless kind == "@"

            id_tokens = id.split('/')
            record_kind = id_tokens.shift
            role_name = id_tokens.pop
            record = Conjur::PolicyParser::Types.const_get(record_kind.classify).new.tap do |record|
              record.id = id_tokens.join('/')
              record.account = account
            end
            new(record, role_name)
          end
        end
        
        def to_s
          role_name = id.split('/')[-1]
          "'#{role_name}' on #{record}"
        end
        
        def account
          record.account
        end
        
        def role_kind
          "@"
        end
        
        def id
          [ record.role_kind, record.id, role_name ].join('/')
        end
      end
    end
  end
end
