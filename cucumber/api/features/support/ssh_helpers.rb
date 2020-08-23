# frozen_string_literal: true

require 'net/ssh'

# Utility methods for performing actions in remote machines
module SshHelpers

  def run_command_in_machine(machine_ip, machine_username, machine_password, command)
    ssh = Net::SSH.start(machine_ip, machine_username, password: machine_password)
    ssh.exec!(command).tap do
      ssh.close
    end
  end

  def run_command_in_machine_with_private_key(machine_ip:, machine_username:, private_key_path:, command:)
    # The SSH command triggered a warning:
    # "bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)\ntotal 0\n"
    # which was included as a prefix of the command output.
    #
    # This can be prevented by altering the ssh configuration on the client
    # (the global file is typically `/etc/ssh/ssh_config`):
    # comment out / remove the following line:
    #  SendEnv LANG LC_*
    #
    # Alternatively the configuration of the server can be changed, by editing `/etc/ssh/sshd_config` on the remote
    # machine (note the d in sshd_config):
    # comment out / remove the following line:
    #  AcceptEnv LANG LC_*
    #
    # Using the Net::SSH.start options
    # --------------------------------
    # from: https://www.rubydoc.info/github/net-ssh/net-ssh/Net/SSH
    # :config => set to true to load the default OpenSSH config files (~/.ssh/config, /etc/ssh_config),
    # or to false to not load them, or to a file-name (or array of file-names) to load those specific configuration
    # files. Defaults to true.
    ssh = Net::SSH.start(machine_ip, machine_username, :keys => [private_key_path], :config => false)
    ssh.exec!(command).tap do
      ssh.close
    end
  end

end

World(SshHelpers)
