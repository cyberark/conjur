#
# Copyright 2013-2017 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'set'

require 'conjur/cert_utils'

module Conjur
  
  class << self
    # Saves the current thread local {Conjur::Configuration},
    # sets the thread local {Conjur::Configuration} to `config`, yields to the block, and ensures that
    # the original thread local configuration is restored.
    #
    # Because Conjur configuration is accessed from the 'global' {Conjur.configuration} method by all Conjur
    # API methods, this method provides the ability to set a thread local value for use within the current,
    # or within a block in a single threaded application.
    #
    # Note that the {Conjur.configuration=} method sets the *global* {Conjur::Configuration}, not the thread-local
    # value.
    #
    # @example Override Configuration in a Thread
    #   # in this rather contrived example, we'll override the {Conjur::Configuration#appliance_url} parameter
    #   # used by calls within a thread.
    #
    #   # Set up the configuration in the main thread
    #   Conjur.configure do |c|
    #     # ...
    #     c.appliance_url = 'https://conjur.main-url.com/api'
    #   end
    #
    #   # Start a new thread that will perform requests to another server.  In practice, you might
    #   # have a web server that uses a Conjur endpoint specified by a request header.
    #   Thread.new do
    #      Conjur.with_configuration Conjur.config.clone(appliance_url: 'https://conjur.local-url.com/api') do
    #         sleep 2
    #         puts "Thread local url is #{Conjur.config.appliance_url}"
    #      end
    #   end
    #   puts "Global url is #{Conjur.config.appliance_url}"
    #   # Outputs:
    #   Global url is https://conjur.main-url.com/api
    #   Thread local url is https://conjur.local-url.com/api
    #
    # @return [void]
    def with_configuration(config)
      oldvalue = Thread.current[:conjur_configuration]
      Thread.current[:conjur_configuration] = config
      yield
    ensure
      Thread.current[:conjur_configuration] = oldvalue
    end
    
    # Gets the current thread-local or global configuration.
    #
    # The thread-local Conjur configuration can only be set using the {Conjur.with_configuration}
    # method.  This method will try to return that value first, then the global configuration as
    # set with {Conjur.configuration=} (which is lazily initialized if not set).
    #
    # @return [Conjur::Configuration] the thread-local or global Conjur configuration.
    def configuration
      Thread.current[:conjur_configuration] || (@config ||= Configuration.new)
    end
    
    # Sets the global configuration.
    #
    # This method *has no effect* on the thread local configuration.  Use {Conjur.with_configuration} instead if
    # that's what you want.
    #
    # @param [Conjur::Configuration] config the new configuration
    # @return [Conjur::Configuration] the new value of the configuration
    def configuration=(config)
      @config = config
    end

    alias config configuration
    alias config= configuration=

    # Configure Conjur with a block.
    #
    # @example
    #   Conjur.configure do |c|
    #     c.account = 'some-account'
    #     c.appliance_url = 'https://conjur.companyname.com/api'
    #   end
    #
    # @yieldparam [Conjur::Configuration] c the configuration instance to modify.
    def configure
      yield configuration
    end
  end

  # Stores a configuration for the Conjur API client.  This class provides *global* and *thread local* storage
  # for common options used by the Conjur API.  Most importantly, it specifies the
  #
  #  * REST endpoints, derived from the {Conjur::Configuration#appliance_url} and {Conjur::Configuration#account} options
  #  * The certificate used for secure connections to the Conjur appliance ({Conjur::Configuration#cert_file})
  #
  # ### Environment Variables
  #
  # Option values used by Conjur can be given by environment variables, using a standard naming scheme. Specifically,
  # an environment variable named `CONJUR_ACCOUNT` will be used to provide a default value for the {Conjur::Configuration#account}
  # option.
  #
  #
  # ### Required Options
  #
  # The {Conjur::Configuration#account} and {Conjur::Configuration#appliance_url} are always required.  Except in
  # special cases, the {Conjur::Configuration#cert_file} is also required, but you may omit it if your Conjur root
  # certificate is in the OpenSSl default certificate store.
  #
  # ### Thread Local Configuration
  #
  # While using a globally available configuration is convenient for most applications, sometimes you will need to
  # use different configurations in different threads.  This is supported by  returning a thread local version from {Conjur.configuration}
  # if one has been set by {Conjur.with_configuration}.
  #
  # @see Conjur.configuration
  # @see Conjur.configure
  # @see Conjur.with_configuration
  #
  # @example Basic Configuration
  #   Conjur.configure do |c|
  #     c.account = 'the-account'
  #     c.cert_file = find_conjur_cert_file
  #   end
  #
  # @example Setting the appliance_url from an environment variable
  #   ENV['CONJUR_APPLIANCE_URL'] = 'https://some-host.com/api'
  #   Conjur::Configuration.new.appliance_url # => 'https://some-host.com/api'
  #
  # @example Using thread local configuration in a web application request handler
  #   # Assume that we're in a request handler thread in a multithreaded web server.
  #
  #   requested_appliance_url = request.header 'X-Conjur-Appliance-Url'
  #
  #   with_configuration Conjur.config.clone(appliance_url: requested_appliance_url) do
  #     # `api` is an instance attribute.  Note that we can use an api that was created
  #     # before we modified the thread local configuration.
  #
  #
  #     # 404 if the user doesn't exist
  #
  #     user = api.user request.header('X-Conjur-Login')
  #     raise HttpError, 404, "User #{user.login} does not exist" unless user.exists?
  #     # ... finish the request
  #   end
  #
  #
  class Configuration
    # @api private
    attr_reader :explicit

    # @api private
    attr_reader :supplied

    # @api private
    attr_reader :computed

    # Create a new {Conjur::Configuration}, setting initial values from
    # `options`.
    #
    # @note `options` must use symbols for keys.
    #
    # @example
    #   Conjur.config = Conjur::Configuration.new account: 'companyname'
    #   Conjur.config.account # => 'companyname'
    #
    # @param [Hash] options hash of options to set on the new instance.
    #
    def initialize options = {}
      @explicit = options.dup
      @supplied = options.dup
      @computed = Hash.new
    end
    
    class << self
      # @api private
      def accepted_options
        require 'set'
        @options ||= Set.new
      end
      
      # @param [Symbol] name
      # @param [Hash] options
      # @option options [Boolean] :boolean (false) whether this option should have a '?' accessor 
      # @option options [Boolean, String] :env Environment variable for this option.  Set to false
      #   to disallow environment based configuration.  Default is CONJUR_<OPTION_NAME>.
      # @option options [Proc, *] :default Default value or proc to provide it
      # @option options [Boolean] :required (false) when true, raise an exception if the option is
      #   not set
      # @option options [Proc, #to_proc] :convert proc-ish to convert environment 
      #   values to appropriate types
      # @param [Proc] def_proc block to provide default values 
      # @api private
      def add_option name, options = {}, &def_proc
        accepted_options << name
        allow_env = options[:env].nil? || options[:env]
        env_var = options[:env] || "CONJUR_#{name.to_s.upcase}"
        def_val = options[:default]
        opt_name = name
        
        def_proc ||= if def_val.respond_to?(:call)
          def_val
        elsif options[:required]
          proc { raise "Missing required option #{opt_name}" }
        else
          proc { def_val }
        end
        
        convert = options[:convert] || ->(x){ x }
        # Allow a Symbol, for example
        convert = convert.to_proc if convert.respond_to?(:to_proc) 

        define_method("#{name}=") do |value|
          set name, value
        end

        define_method("#{name}_env_var") do
          allow_env ? env_var : nil
        end
        
        define_method(name) do
          value = computed[name]
          return value unless value.nil?

          if supplied.member?(name)
            supplied[name]
          elsif allow_env && ENV.member?(env_var)
            instance_exec(ENV[env_var], &convert)
          else 
            instance_eval(&def_proc)
          end.tap do |value|
            computed[name] = value
          end
        end

        alias_method("#{name}?", name) if options[:boolean]
      end
    end
    
    # Return a copy of this {Conjur::Configuration} instance, optionally
    # updating the copy with options from the `override_options` hash.
    #
    # @example
    #   original = Conjur.configuration
    #   original.account  # => 'conjur'
    #   copy = original.clone account: 'some-other-account'
    #   copy.account    # => 'some-other-account'
    #   original.account # => 'conjur'
    #
    # @param [Hash] override_options options to set on the new instance
    # @return [Conjur::Configuration] a copy of this configuration
    def clone override_options = {}
      self.class.new self.explicit.dup.merge(override_options)
    end

    # Manually set an option.  Note that setting an option not present in
    # {Conjur::Configuration.accepted_options} is a no op.
    # @api private
    # @param [Symbol, String] key the name of the option to set
    # @param [Object] value the option value.
    def set(key, value)
      if self.class.accepted_options.include?(key.to_sym)
        explicit[key.to_sym] = value
        supplied[key.to_sym] = value
        computed.clear
      end
    end

    # @!attribute authn_url
    #
    # The url for the {http://developer.conjur.net/reference/services/authentication Conjur authentication service}.
    #
    # By default, this will be built from the +appliance_url+. To use a custom authenticator, 
    # set this option in code or set `CONJUR_AUTHN_URL`. 
    #
    #
    # @return [String] the authentication service url
    add_option :authn_url do
      global_service_url 0, service_name: 'authn'
    end

    # @!attribute core_url
    #
    # The url for the core Conjur services.
    #
    # @note You should not generally set this value.  Instead, Conjur will derive it from the
    #   {Conjur::Configuration#account} and {Conjur::Configuration#appliance_url}
    #   properties.
    #
    # @return [String] the base service url
    add_option :core_url do
      global_service_url 0
    end

    # @!attribute appliance_url
    # The url for your Conjur appliance.
    #
    # If your appliance's hostname is `'conjur.companyname.com'`, then your `appliance_url` will
    # be `'https://conjur.companyname.com/api'`.
    #
    # @note If you are using an appliance (if you're not sure, you probably are), this option is *required*.
    #
    # @return [String] the appliance URL
    add_option :appliance_url

    # NOTE DO NOT DOCUMENT THIS AS AN ATTRIBUTE, IT IS PRIVATE AND YARD DOESN'T SUPPORT @api private ON ATTRIBUTES.
    #
    # The port used to derive ports for conjur services running locally. You will only use this if you are
    # running the Conjur services locally, in which case you are probably a Conjur developer, and should ask
    # someone in chat ;-)
    #
    add_option :service_base_port, default: 5000

    # @!attribute account
    # The organizational account used by Conjur.
    #
    # On Conjur appliances, this option will be set once when the appliance is first configured.  You can get the
    # value for the acccount option from your conjur administrator, or if you have installed
    # the {http://developer.conjur.net/client_setup/cli.html Conjur command line tools} by running
    # {http://developer.conjur.net/reference/services/authentication/whoami.html conjur authn whoami},
    # or examining your {http://developer.conjur.net/client_setup/cli.html#Configure .conjurrc file}.
    #
    # @note this option is **required**, and attempting to make any api calls prior to setting it (either
    #   explicitly or with the `"CONJUR_ACCOUNT"` environment variable) will raise an exception.
    #
    # @return [String]
    add_option :account, required: true

    # @!attribute cert_file
    #
    # Path to the certificate file to use when making secure connections to your Conjur appliance.
    #
    # This should be the path to the root Conjur SSL certificate in PEM format. You will normally get the
    # certificate file using the {http://developer.conjur.net/reference/tools/utilities/init.html conjur init} command.
    # This option is not required if the certificate or its root is in the OpenSSL default cert store.
    # If your program throws an error indicating that SSL verification has failed, you probably need
    # to set or fix this option.
    #
    # @return [String, nil] path to the certificate file, or nil if you aren't using one.
    add_option :cert_file

    # @!attribute ssl_certificate
    #
    # Contents of a certificate file.  This can be used instead of :cert_file in environments like Heroku where  you
    # can't use a certificate file.
    #
    # This option overrides the value of {#cert_file} if both are given, and issues a warning.
    #
    # @see cert_file
    add_option :ssl_certificate

    # @!attribute version
    #
    # Selects the major API version of the Conjur server. With this setting, the API
    # will use the routing scheme for API version `4` or `5`. 
    #
    # Methods which are not available in the selected version will raise NoMethodError.
    add_option :version, default: 5

    # @!attribute authn_local_socket
    #
    # File path to the Unix socket used for local authentication.
    # This is only available when the API client is running on the Conjur server.
    add_option :authn_local_socket, default: "/run/authn-local/.socket"

    # Calls a major-version-specific function.
    def version_logic v4_logic, v5_logic
      case version.to_s
      when "4"
        v4_logic.call
      when "5"
        v5_logic.call
      else
        raise "Unsupported major version #{version}"
      end
    end

    # Add the certificate configured by the {#ssl_certificate} and {#cert_file} options to the certificate
    # store used by Conjur clients.
    #
    # @param [OpenSSL::X509::Store] store the certificate store that the certificate will be installed in.
    # @return [Boolean]  whether a certificate was added to the store.
    def apply_cert_config! store=OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE
      if ssl_certificate
        CertUtils.parse_certs(ssl_certificate).each do |cert|
          begin
            store.add_cert cert
          rescue OpenSSL::X509::StoreError => ex
            raise unless ex.message == 'cert already in hash table'
          end
        end
      elsif cert_file
        ensure_cert_readable!(cert_file)
        store.add_file cert_file
      else
        return false
      end
      true
    end

    private

    def global_service_url service_port_offset, service_name: nil
      if appliance_url
        URI.join([appliance_url, service_name].compact.join('/')).to_s
      else
        "http://localhost:#{service_base_port + service_port_offset}"
      end
    end

    def ensure_cert_readable!(path)
      # Try to open the file to make sure it exists and that it's
      # readable. Don't rescue exceptions from it, just let them
      # propagate.
      File.open(path) {}
    end
  end
end
