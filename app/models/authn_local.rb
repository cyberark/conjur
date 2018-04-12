require 'timeout'
require 'fileutils'
require 'socket'

AuthnLocal = Struct.new(:socket, :queue_length, :timeout) do
  class << self
    def run socket:, queue_length:, timeout:
      socket ||= '/run/authn-local/.socket'
      socket_dir = File.dirname(socket)

      unless File.directory?(socket_dir)
        $stderr.puts "authn-local requires directory #{socket_dir.inspect} to exist and be a directory"
        $stderr.puts "authn-local will not be enabled"
        return
      end

      queue_length ||= 5
      queue_length = queue_length.to_i

      timeout ||= 1
      timeout = timeout.to_i

      AuthnLocal.new(socket, queue_length, timeout).run
    end
  end

  def run
    FileUtils.rm_rf socket

    server = UNIXServer.new socket

    trap(0) do
      # remove the socket on exit
      # alternatively it can be removed on startup
      # (or both)
      $stderr.puts "Removing socket #{socket}"
      File.unlink socket
    end

    server.listen queue_length

    puts "authn-local is listening at #{socket}"

    while conn = server.accept
      begin
        Timeout.timeout timeout do
          claims = conn.gets.strip
          begin
            conn.puts issue_token(claims)
          rescue
            $stderr.puts "Error in authn-local: #{$!.to_s}"
            conn.puts
          ensure
            conn.close
          end
        end
      rescue Timeout::Error
        $stderr.puts "Timeout::Error in authn-local"
      end
    end
  end

  def issue_token claims
    claims = JSON.parse(claims)
    claims = claims.slice("account", "sub", "exp", "cidr", "service_id", "authn_type")
    @account = claims.delete("account") or raise "'account' is required"
    @authn_type = claims['authn_type']
    service_id = claims['service_id']
    raise "'sub' is required" unless claims['sub']

    puts "Checking sec req: #{service_id}, #{@account}, #{@authn_type}, #{claims['sub']}"
    validate_security_requirements service_id, claims['sub'] if service_id && @authn_type

    key = Slosilo["authn:#{@account}"]
    if key 
      key.issue_jwt(claims).to_json
    else
      raise "No signing key found for account #{@account.inspect}"
    end
  end

  def validate_security_requirements service_id, user_id
    security_requirements.validate(service_id, user_id)
  end

  def security_requirements
    AuthenticatorSecurity.new(
      authn_type: @authn_type,
      account: @account,
      whitelisted_authenticators: ENV['CONJUR_AUTHENTICATORS']
    )
  end
end
