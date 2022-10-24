module Conjur
  module Extension
    # ImplementationMethod encapsulates a call to a Conjur Extension that
    # safely proxies arguments to extension based on how the extension
    # method was implemented. For example, if the extension call includes
    # an argument, but the extension implementation doesn't define a parameter
    # to accept it, then the method call would fail if call naively. So we
    # finess the method calls to allow extensions to "just work" as much as
    # possible.
    class ImplementationMethod
      def initialize(
        implementation_object:,
        method:,
        **kwargs
      )
        @implementation_object = implementation_object
        @method = method
        @kwargs = kwargs
      end

      def call
        # If the target method doesn't accept any parameters, we won't try to
        # send any
        if target_parameters.length.zero?
          return @implementation_object.send(@method)
        end

        # If the target method declares parameters we can't provide, raise
        # an error message with enough detail to identify the issue and
        # resolve it
        unless invalid_parameters.length.zero?
          message = "Invalid target method parameters: " \
                    "#{invalid_parameter_names.join(', ')}. The method " \
                    "parameters must be empty or keyword args."

          unless @kwargs.empty?
            message += " The only required keyword arguments allowed are: " \
                       "#{@kwargs.keys.join(', ')}"
          end

          raise StandardError, message
        end

        # If the given keyword args match the expected arguments, call the
        # method
        @implementation_object.send(@method, **@kwargs)
      end

      protected

      def target_parameters
        if @method == :new
          # If we're trying to call :new on a class, we actually need to check
          # the parameters on the :initialize instance method.
          @implementation_object.instance_method(:initialize).parameters
        else
          @implementation_object.method(@method).parameters
        end
      end

      def invalid_parameter_names
        invalid_parameters.map { |param| param[1] }
      end

      def invalid_parameters
        # Determine which parameters are invalid, by filtering out those
        # that are valid.
        @invalid_parameters ||= target_parameters.reject do |param|
          param_type, param_name = param
          # A parameter is valid if it's one of our known named kwargs
          if param_type == :keyreq && @kwargs.keys.include?(param_name)
            next true
          end

          # A parameter is valid if it's optional, otherwise it's invalid
          next %i[opt key rest keyrest block].include?(param_type)
        end
      end
    end
  end
end
