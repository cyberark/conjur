module CredentialFactory
  # Echos the value of a dependent variable.
  #
  # This is useful for testing.
  Echo = Struct.new(:resource, :dependent_secrets) do
    include Base

    class << self
      # Requires a variable indicated by the annotation 'credential-factory/variable'.
      def dependent_variable_ids annotations
        [ require_annotation(annotations, 'credential-factory/variable') ]
      end
    end

    def values
      [ dependent_secrets[:password] ]
    end
  end
end
