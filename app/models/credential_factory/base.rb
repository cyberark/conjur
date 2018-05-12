module CredentialFactory
  module Base
    def self.included cls
      cls.extend ClassMethods
    end

    def annotations
      resource.annotations.inject({}) do |memo, entry|
        memo[entry.name] = entry.value
        memo
      end
    end

    def require_annotation name
      self.class.require_annotation annotations, name
    end

    module ClassMethods
      # Require annotation +name+ to be in the hash +annotations+, or a configuration error is raised.
      def require_annotation annotations, name
        annotations[name] or raise ArgumentError, "Annotation #{name.inspect} is required"
      end

      # From an example annotation name, build a set of annotation names which are related by 
      # the prefix on the example. If the example is 'aws/ci/secret_access_key' and the +names+ are
      # 'foo' and 'bar', this method returns 'aws/ci/foo' and 'aws/ci/bar'. 
      def build_variable_ids example, names
        tokens = example.split('/')
        tokens.pop
        names.map do |name|
          (tokens + [ name ]).join('/')
        end
      end
    end
  end
end
