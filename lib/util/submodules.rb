module Util
  class Submodules
    def self.of(mod)
      mod.constants
        .map { |c| mod.const_get(c) }
        .select { |x| x.is_a?(Module) }
    end
  end
end

__END__
#
# Test Code, should be moved to unit test

module A
  class MyCoolAuth
    class Authenticator
      def valid?; end
    end
  end

  class Ldap
    class Authenticator
      def valid?; end
    end
    class Blah
    end
  end

  class DontInclude
    class Blah
      def valid?; end
    end
  end
  
end

x = Submodules.new(A)
  .flat_map { |mod| Submodules.new(mod) }
  .select { |cls| AuthenticatorClass.valid?(cls) }
  .map { |cls| [AuthenticatorClass.new(cls).url_name, cls] }
  .to_h

p x
