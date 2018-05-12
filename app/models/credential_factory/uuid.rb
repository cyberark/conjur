module CredentialFactory
  # Provides a single securely random UUID.
  Uuid = Struct.new(:resource, :dependent_secrets) do
    include Base

    class << self
      # No dependent variables are required.
      def dependent_variable_ids annotations
        []
      end
    end

    def values
      [ SecureRandom.uuid ]
    end
  end
end
