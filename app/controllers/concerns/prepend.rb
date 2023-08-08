module ReadOnlyPrepender
    # Given a list of method symbols, preempt calls to them using a proxy that
    # raises an error if read_only is enabled.
    def write_protected(*method_names)
      method_names.each do |m|
        proxy = Module.new do
          define_method(m) do |*args|
            raise ::Errors::Conjur::ReadOnly::ActionNotPermitted unless !Rails.configuration.read_only
            super *args
          end
        end
        self.prepend proxy
      end
    end
  end
