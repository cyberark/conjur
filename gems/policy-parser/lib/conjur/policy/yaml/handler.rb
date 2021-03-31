module Conjur
  module PolicyParser
    module YAML
      class Handler < Psych::Handler
        include Conjur::PolicyParser::Logger

        attr_accessor :parser, :filename, :result
        
        # An abstract Base handler. The handler will receive each document message within
        # its particular context (sequence, mapping, etc).
        #
        # The handler can decide that the message is not allowed by not implementing the message.
        #
        class Base
          attr_reader :parent, :anchor
          
          def initialize parent, anchor
            @parent = parent
            @anchor = anchor
          end
          
          # Handlers are organized in a stack. Each handler can find the root Handler by traversing up the stack.
          def handler
            parent.handler
          end
          
          # Push this handler onto the stack.
          def push_handler
            handler.push_handler(self)
          end
          
          # Pop this handler off the stack, indicating that it's complete.
          def pop_handler
            handler.pop_handler
          end
          
          # An alias is encountered in the document. The value may be looked up in the root Handler +anchor+ hash.
          def alias anchor
            raise "Unexpected alias #{anchor}"
          end
          
          # Start a new mapping with the specified tag. 
          # If the handler wants to accept the message, it should return a new handler.
          def start_mapping _tag, _anchor
            raise "Unexpected mapping"
          end
          
          # Start a new sequence.
          # If the handler wants to accept the message, it should return a new handler.
          def start_sequence _anchor
            raise "Unexpected sequence"
          end
          
          # End the current sequence. The handler should populate the sequence into the parent handler.
          def end_sequence
            raise "Unexpected end of sequence"
          end
          
          # End the current mapping. The handler should populate the mapping into the parent handler.
          def end_mapping
            raise "Unexpected end of mapping"
          end
          
          # Process a scalar value. It may be a map key, a map value, or a sequence value.
          def scalar _value, _tag, _quoted, _anchor
            raise "Unexpected scalar"
          end
          
          protected
          
          def scalar_value value, tag, quoted, record_type
            if type = type_of(tag, record_type)
              type.new.tap do |record|
                record.id = value
              end
            else
              SafeYAML::Transform.to_guessed_type(value, quoted, SafeYAML::OPTIONS)
            end
          end
          
          def type_of tag, record_type
            if tag&.match(/!(.*)/)
              type_name = Regexp.last_match(1).underscore.camelize
              begin
                Conjur::PolicyParser::Types.const_get(type_name)
              rescue NameError
                raise "Unrecognized data type '#{tag}'"
              end
            else
              record_type
            end
          end
        end
        
        # Handles the root document, which should be a sequence.
        class Root < Base
          attr_reader :result, :handler, :handler
          
          def initialize handler
            super(nil, nil)
            
            @handler = handler
            @result = nil
          end          
          
          def sequence seq
            raise "Already got sequence result" if @result

            @result = seq
          end
          
          # The document root is expected to start with a sequence. 
          # A Sequence handler is constructed with no implicit type. This
          # sub-handler handles the message.
          def start_sequence anchor
            Sequence.new(self, anchor, nil).tap(&:push_handler)
          end
          
          # Finish the sequence, and the document.
          def end_sequence
            pop_handler
          end
        end
        
        # Handles a sequence. The sequence has:
        # +record_type+ default record type, inferred from the field name on the parent record.
        # +args+ the start_sequence arguments.
        class Sequence < Base
          attr_reader :record_type
          
          def initialize parent, anchor, record_type
            super(parent, anchor)
            
            @record_type = record_type
            @list = []
          end
          
          # Adds a mapping to the sequence.
          def mapping value
            handler.log { "#{handler.indent}Adding mapping #{value} to sequence" }
            @list.push(value)
          end
  
          # Adds a sequence to the sequence.
          def sequence value
            handler.log { "#{handler.indent}Adding sequence #{value} to sequence" }
            @list.push(value)
          end
          
          # When the sequence receives an alias, the alias should be mapped to the previously stored 
          # value and added to the result list.
          def alias anchor
            handler.log { "#{handler.indent}Adding alias *#{anchor} to sequence, whose value is #{handler.anchor(anchor)}" }
            @list.push(handler.anchor(anchor))
          end
          
          # When the sequence contains a mapping, a new record should be created corresponding to either:
          #
          # * The explicit stated type (tag) of the mapping
          # * The implicit field type of the sequence
          #
          # If neither of these is available, it's an error.
          def start_mapping tag, anchor
            if type = type_of(tag, record_type)
              Mapping.new(self, anchor, type).tap(&:push_handler)
            else
              raise "No type given or inferred for sequence entry"
            end
          end
          
          # Process a sequence within a sequence.
          def start_sequence anchor
            Sequence.new(self, anchor, record_type).tap(&:push_handler)
          end
          
          # When the sequence contains a scalar, the value should be appended to the result.
          def scalar value, tag, quoted, anchor
            scalar_value(value, tag, quoted, record_type).tap do |value|
              handler.log { "#{handler.indent}Adding scalar *#{value} to sequence" }
              @list.push(value)
              handler.anchor(anchor, value) if anchor
            end
          end
          
          def end_sequence
            parent.sequence(@list)
            handler.anchor(anchor, @list) if anchor
            pop_handler
          end
        end
        
        # Handles a mapping, each of which will be parsed into a structured record.
        class Mapping < Base
          attr_reader :type
          
          def initialize parent, anchor, type
            super(parent, anchor)
            @existing_members = Set.new
            @record = type.new
          end
  
          def map_entry key, value
            handler.log { "#{handler.indent}Setting map entry #{key} = #{value}" }
            if @record.respond_to?(:[]=)
              @record.send(:[]=, key, value)
            else
              begin
                @record.send("#{key}=", value)
              rescue NoMethodError
                raise "No such attribute '#{key}' on type #{@record.class.short_name}"
              end
            end
          end
          
          # Begins a mapping with the anchor value as the key.
          def alias anchor
            key = handler.anchor(anchor)
            MapEntry.new(self, nil, @record, key).tap(&:push_handler)
          end
  
          # Begins a new map entry.
          def scalar value, tag, quoted, anchor
            if @existing_members.include?(value)
              raise "Duplicate attribute: #{value}"
            else
              @existing_members.add(value)
            end

            value = scalar_value(value, tag, quoted, type)
            MapEntry.new(self, anchor, @record, value).tap(&:push_handler)
          end
          
          def end_mapping
            parent.mapping(@record)
            handler.anchor(anchor, @record) if anchor
            pop_handler
          end
        end
        
        # Processes a map entry. At this point, the parent record and the map key are known.
        class MapEntry < Base
          attr_reader :record, :key
  
          def initialize parent, anchor, record, key
            super(parent, anchor)
            
            @record = record
            @key = key
          end
          
          def sequence value
            value(value)
          end
          
          def mapping value
            value(value)
          end
          
          def value value
            parent.map_entry(@key, value)
            handler.anchor(anchor, value) if anchor
            pop_handler
          end
          
          # Interpret the alias as the map value and populate in the parent.
          def alias anchor
            value(handler.anchor(anchor))
          end
          
          # Start a mapping as a map value.
          def start_mapping tag, anchor
            if type = type_of(tag, yaml_field_type(key))
              Mapping.new(self, anchor, type).tap(&:push_handler)
            else
              # We got a mapping on a simple type
              raise "Attribute '#{key}' can't be a mapping"
            end
          end
          
          # Start a sequence as a map value.
          def start_sequence anchor
            Sequence.new(self, anchor, yaml_field_type(key)).tap(&:push_handler)
          end
          
          def scalar value, tag, quoted, _anchor
            value(scalar_value(value, tag, quoted, yaml_field_type(key)))
          end
          
          protected
          
          def yaml_field_type key
            record.class.respond_to?(:yaml_field_type) ? record.class.yaml_field_type(key) : nil
          end
        end
        
        def initialize
          @root = Root.new(self)
          @handlers = [ @root ]
          @anchors = {}
          @filename = "<no-filename>"
        end
        
        def result
          @root.result
        end
        
        def push_handler handler
          @handlers.push(handler)
          log {"#{indent}pushed handler #{handler.class}"}
        end
          
        def pop_handler
          @handlers.pop
          log {"#{indent}popped to handler #{handler.class}"}
        end
        
        # Get or set an anchor. Invoke with just the anchor name to get the value.
        # Invoke with the anchor name and value to set the value.
        def anchor *args
          key, value, = args
          unless [1, 2].include?(args.length)
            raise ArgumentError, "Expecting 1 or 2 arguments, got #{args.length}"
          end

          if key && value
            raise "Duplicate anchor #{key}" if @anchors[key]

            @anchors[key] = value
          elsif key
            @anchors[key]
          end
        end
        
        def handler 
          @handlers.last 
        end
        
        def alias key
          log {"#{indent}WARNING: anchor '#{key}' is not defined"} unless anchor(key)
          log {"#{indent}anchor '#{key}'=#{anchor(key)}"}
          handler.alias(key)
        end
        
        def start_mapping *args
          log {"#{indent}start mapping #{args}"}
          anchor, tag, = args
          tag = "!automatic-role" if %w[!managed-role !managed_role].include?(tag)
          handler.start_mapping(tag, anchor)
        end
        
        def start_sequence *args
          log {"#{indent}start sequence : #{args}"}
          anchor, = args
          handler.start_sequence(anchor)
        end
        
        def end_sequence
          log {"#{indent}end sequence"}
          handler.end_sequence
        end
        
        def end_mapping
          log {"#{indent}end mapping"}
          handler.end_mapping
        end
        
        def scalar *args
          # value, anchor, tag, plain, quoted, style
          value, anchor, tag, _, quoted = args
          log {"#{indent}got scalar #{tag ? "#{tag}=" : ''}#{value}#{anchor ? "##{anchor}" : ''}"}
          handler.scalar(value, tag, quoted, anchor)
        end
        
        def log(&block)
          logger.debug('conjur/policy/handler', &block)
        end
        
        def indent
          "  " * [ @handlers.length - 1, 0 ].max
        end
      end
    end
  end
end
