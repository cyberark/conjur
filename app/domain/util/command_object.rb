module Util
  module CommandObject

    def dependencies(**hash)
      @_dependencies = hash
    end

    def input(*args)

      # args_signature = args.join(',')

      attr_readers = "attr_reader #{@_dependencies.keys.map(&:inspect).join(',')}"
      call_attr_readers = "attr_reader #{args.map(&:inspect).join(',')}"
      expected_call_hash_keys = args.sort.map(&:inspect).join(',')

      call_ctor_args = (@_dependencies.keys.sort + args)
      call_ctor_signature = (@_dependencies.keys.sort + args).join(',')
      set_call_attrs = call_ctor_args.map {|k| "@#{k} = #{k}" }.join(';')


      class_eval <<~RUBY
      #{attr_readers}

      class Call < #{self}
      #{call_attr_readers}

        def initialize(#{ call_ctor_signature })
      #{set_call_attrs}
        end
      end

      def initialize(**hash)
        validate_dependencies(hash)
        deps = deps_.merge(hash)
        deps.each { |name, val| instance_variable_set('@' + name.to_s, val) }
      end

      # We allow either args, or a hash, but not both
      #
      def call(*args, **hash_args)

        validate_call_args(args, hash_args)
        if hash_args.empty?
          all_args = dep_args + args
          Call.new(*all_args).()
        else
          all_args = dep_args + hash_args.values
          Call.new(*all_args).()
        end

      end

      private

      def validate_dependencies(hash)
        unknown_deps = hash.keys - required_ctor_keys
        valid = unknown_deps.empty?
        return if valid
        raise "Unexpected dependencies: " + required_ctor_keys.to_s
      end

      def dep_args
        required_ctor_keys.map {|x| send(x) }
      end

      def validate_call_args(args, hash_args)
        arg_cnt = [args, hash_args].count { |x| x.empty? }
        raise "Cannot mix named and unnamed arguments" unless arg_cnt == 1
        validate_call_hash_args(hash_args) unless hash_args.empty?
      end

      def validate_call_hash_args(hash)
        expected = [#{expected_call_hash_keys}]
        err = "call requires these hash keys: #{expected_call_hash_keys}"
        raise err unless hash.keys.sort == expected
      end

      def required_ctor_keys
        deps_.keys.sort
      end

      def deps_
        self.class.instance_variable_get('@_dependencies')
      end
      RUBY
    end

    def steps(*args)
      class_eval <<~RUBY
      class Call
        def call
      #{args.join(';')}
        end
      end
      RUBY
    end
  end
end
