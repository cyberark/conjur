require 'conjur/cidr'

module Conjur
  module PolicyParser
    module Types
      # An inheritable class attribute which is cloned by subclasses so the attribute
      # can be a mutable thing such as a Hash.
      #
      # https://raw.githubusercontent.com/apotonick/uber/master/lib/uber/inheritable_attr.rb
      module InheritableAttribute
        def inheritable_attr(name, options = {})
          instance_eval("
            def #{name}=(v)
              @#{name} = v
            end
    
            def #{name}
              return @#{name} if instance_variable_defined?(:@#{name})
              @#{name} = InheritableAttribute.inherit_for(self, :#{name}, #{options})
            end
          ")
        end
    
        def self.inherit_for(klass, name, options = {})
          return unless klass.superclass.respond_to?(name)
    
          value = klass.superclass.send(name) # could be nil
    
          return value if options[:clone] == false

          Clone.(value) # this could be dynamic, allowing other inheritance strategies.
        end
    
        class Clone
          # The second argument allows injecting more types.
          def self.call(value, uncloneable = uncloneable())
            uncloneable.each { |klass| return value if value.is_a?(klass) }
            value.clone
          end
    
          def self.uncloneable
            [Symbol, TrueClass, FalseClass, NilClass]
          end
        end
      end
      
      # Methods which type-check and transform attributes. Type-checking can be done by 
      # duck-typing, with +is_a?+, or by a procedure.
      module TypeChecking
        # This is the primary function of the module.
        #
        # +value+ an input value
        # +type_name+ used only for error messages.
        # +test_function+ a class or function which will determine if the value is already the correct type.
        # +converter+ if the +test_function+ fails, the converter is called to coerce the type. 
        # It should return +nil+ if its unable to do so.
        def expect_type attr_name, value, type_name, test_function, converter = nil
          if test_function.is_a?(Class)
            cls = test_function
            test_function = ->{ value.is_a?(cls) } 
          end
          if test_function.call
            value
          elsif converter && (v = converter.call)
            v
          else
            name = value.class.respond_to?(:short_name) ? value.class.short_name : value.class.name
            raise "Expected a #{type_name} for field '#{attr_name}', got #{name}"
          end
        end

        # Duck-type roles.
        def test_role r
          r.respond_to?(:role?) && r.role?          
        end
        
        # Duck-type resources.
        def test_resource r
          r.respond_to?(:resource?) && r.resource?
        end
        
        # If it's a Record
        def expect_record name, value
          expect_type(name, value, "Record", ->{ value.is_a?(Record) })
        end
        
        # If it's a Layer
        def expect_layer name, value
          expect_type(name, value, "Layer", ->{ value.is_a?(Layer) })
        end
        
        # If it looks like a resource.
        def expect_resource name, value
          expect_type(name, value, "Resource", ->{ test_resource(value) })
        end
        
        # If it looks like a role.
        def expect_role name, value
          expect_type(name, value, "Role", ->{ test_role(value) })
        end
        
        # +value+ may be a Member; Roles can also be converted to Members.
        def expect_member name, value
          expect_type(name,
                      value, 
                      "Member", 
                      Member,
                      ->{ Member.new(value) if test_role(value) })
        end
        
        # +value+ must be a Permission.
        def expect_permission name, value
          expect_type(name,
                      value,
                      "Permission", 
                      Permission)
        end
                  
        # +value+ must be a String.
        def expect_string name, value
          expect_type(name,
                      value, 
                      "string",
                      String)
        end

        # +value+ must be a CIDR.
        def expect_cidr name, value
          validate_cidr = lambda do
            cidr = Conjur::CIDR.new(value)

            unless cidr.ipv4?
              raise "Invalid IP address or CIDR range '#{value}': Address must be IPv4"
            end

            unless cidr.valid_input?
              raise "Invalid IP address or CIDR range '#{value}': Value has " \
                "bits set to right of mask. Did you mean '#{cidr}'?"
            end

            true # CIDR is valid
          rescue IPAddr::Error
            raise "Invalid IP address or CIDR range '#{value}'"
          end

          expect_type(name,
                      value,
                      "CIDR",
                      validate_cidr)
        end

        # +value+ must be a Integer.
        def expect_integer name, value
          expect_type(name,
                      value,
                      "integer",
                      Integer)
        end
                
        # +value+ can be a Hash, or an object which implements +to_h+.
        def expect_hash name, value
          expect_type(name,
                      value,
                      "hash",
                      ->{ value.is_a?(Hash)},
                      ->{ value.to_h.stringify_keys if value.respond_to?(:to_h) })
        end
        
        # +v+ must be +true+ or +false+.
        def expect_boolean name, v
          v = true if v == "true"
          v = false if v == "false"
          expect_type(name,
                      v,
                      "boolean",
                      ->{ [ true, false ].member?(v) })
        end
        
        # +values+ can be an instance of +type+ (as determined by the type-checking methods), or
        # it must be an array of them.
        def expect_array name, kind, values
          # Hash gets converted to an array of key/value pairs by Array
          is_hash = values.is_a?(Hash)
          values = [values] if is_hash

          result = Array(values).map do |v|
            send("expect_#{kind}", name, v)
          end

          values.is_a?(Array) && !is_hash ? result : result[0]
        end
      end
      
      # Define type-checked attributes, using the facilities defined in 
      # +TypeChecking+.
      module AttributeDefinition
        # Define a singular field.
        #
        # +attr+ the name of the field
        # +kind+ the type of the field, which corresponds to a +TypeChecking+ method.
        # +type+ a DSL object type which the parser should use to process the field.
        # This option is not used for simple kinds like :boolean and :string, because they are
        # not structured objects.
        def define_field attr, kind, type = nil, dsl_accessor = false
          register_yaml_field(attr.to_s, type) if type
          register_field(attr.to_s, kind) if kind
          
          if dsl_accessor
            define_method(attr) do |*args|
              v = args.shift
              if v
                existing = instance_variable_get("@#{attr}")
                value = if existing
                  Array(existing) + [ v ]
                else
                  v
                end
                instance_variable_set("@#{attr}", self.class.expect_array(attr, kind, value))
              else
                instance_variable_get("@#{attr}")
              end
            end
          else
            define_method(attr) do
              instance_variable_get("@#{attr}")
            end
          end
          define_method("#{attr}=") do |v|
            instance_variable_set("@#{attr}", self.class.expect_array(attr, kind, v))
          end
        end
        
        # Define a plural field. A plural field is basically just an alias to the singular field.
        # For example, a plural field called +members+ is really just an alias to +member+. Both
        # +member+ and +members+ will accept single values or Arrays of values.
        def define_plural_field attr, kind, type = nil, dsl_accessor = false
          define_field(attr, kind.to_s, type, dsl_accessor)
          
          register_yaml_field(attr.to_s.pluralize, type) if type
          
          define_method(attr.to_s.pluralize) do |*args|
            send(attr, *args)
          end
          define_method("#{attr.to_s.pluralize}=") do |v|
            send("#{attr}=", v)
          end
        end
        
        # This is the primary method used by concrete types to define their attributes. 
        #
        # +attr+ the singularized attribute name.
        # 
        # Options:
        # +type+ a structured type to be constructed by the parser. If not provided, the type
        # may be inferred from the attribute name (e.g. an attribute called :member is the type +Member+).
        # +kind+ the symbolic name of the type. Inferred from the type, if the type is provided. Otherwise
        # it's mandatory.
        # +singular+ by default, attributes accept multiple values. This flag restricts the attribute
        # to a single value only.
        def attribute attr, options = {}
          type = options[:type]
          begin
            type ||= Conjur::PolicyParser::Types.const_get(attr.to_s.capitalize) 
          rescue NameError
          end
          type = nil if type == String
          kind = options[:kind] 
          kind ||= type.short_name.downcase.to_sym if type
          
          raise "Attribute :kind must be defined, explicitly or inferred from :type" unless kind
          
          if options[:singular]
            define_field(attr, kind, type, options[:dsl_accessor])
          else
            define_plural_field(attr, kind, type, options[:dsl_accessor])
          end
        end
        
        # Ruby type for attribute name.
        def yaml_field_type name
          yaml_fields[name]
        end
        
        # Is there a Ruby type for a named field?
        def yaml_field? name
          !!yaml_fields[name]
        end
        
        # Is there a semantic kind for a named field?
        def field? name
          !!fields[name]
        end
                  
        protected
        
        # +nodoc+
        def register_yaml_field field_name, type
          raise "YAML field #{field_name} already defined on #{name} as #{yaml_fields[field_name]}" if yaml_field?(field_name)

          yaml_fields[field_name] = type
        end
        
        # +nodoc+
        def register_field field_name, kind
          raise "YAML field #{field_name} already defined on #{name} as #{fields[field_name]}" if field?(field_name)

          fields[field_name] = kind
        end
      end
      
      # Base class for implementing structured DSL object types such as Role, User, etc.
      #
      # To define a type:
      # 
      # * Inherit from this class
      # * Define attributes using +attribute+
      #
      # Your new type will automatically be registered with the YAML parser with a tag
      # corresponding to the lower-cased short name of the class. 
      class Base
        extend InheritableAttribute
        extend TypeChecking
        extend AttributeDefinition
        
        # Stores the mapping from attribute names to Ruby class names that will be constructed
        # to populate the attribute.
        inheritable_attr :yaml_fields

        # Stores the mapping from attribute names to semantic kind names.
        inheritable_attr :fields
        
        # +nodoc+
        self.yaml_fields = {}

        # +nodoc+
        self.fields = {}

        # Things aren't roles by default
        def role?
          false
        end
        
        def id_attribute 
          'id' 
        end
        
        def custom_attribute_names
          [ ]
        end

        # True if the statement performs a deletion.
        def delete_statement?
          false
        end
        
        def resource?
          false
        end
        
        def role?
          false
        end
        
        # Gets all 'child' records.
        def referenced_records
          result = []
          instance_variables.map do |var|
            value = instance_variable_get(var)
            Array(value).each do |val|
              result.push(val) if val.is_a?(Conjur::PolicyParser::Types::Base)
            end
          end
          result.flatten
        end

        # ID of the 'subject' of this record, ie. the thing that's being acted
        # upon. This is used to perform sanity checks against acting on
        # unqualified objects.
        def subject_id
          raise ArgumentError, "#subject_id not implemented for #{self.class}"
        end
        
        class << self
          # Hook to register the YAML type.
          def inherited cls
            cls.register_yaml_type(cls.short_name.underscore.gsub('_', '-'))
          end
          
          # The last token in the ::-separated class name.
          def short_name
            name.demodulize
          end
          
          alias simple_name short_name
          
          def register_yaml_type simple_name
            ::YAML.add_tag("!#{simple_name}", self)
          end
        end
      end
      
      # Define DSL accessor for Role +member+ field.
      module RoleMemberDSL
        def self.included(base)
          base.module_eval do
            alias_method(:member_accessor, :member)
            
            def member r = nil, admin_option = false
              if r
                member = Member.new(r)
                member.admin = true if admin_option == true
                self.member = if self.member
                  Array(self.member).push(member)
                else
                  member
                end
              else
                member_accessor
              end
            end
          end
        end
      end
      
      # Base class for resource operations like 'permit' and 'deny'
      class ResourceOpBase < Base
        def subject_id
          Array(resource).map(&:id)
        end

        class << self
          # Yes, it's :reek:ControlParameter, I suppose,
          # however this is the interface.
          def role member = nil, grant_option = nil
            return super unless member

            role = Member.new(member)
            role.admin = true if grant_option == true
            self.role = Array(super) << role
          end
        end
      end
      
      module AutomaticRoleDSL
        def automatic_role record, role_name
          AutomaticRole.new(record, role_name)
        end
      end
    end
  end
end
