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

  def run_command_in_machine_with_private_key(machine_ip, machine_username, private_key_path, command)
    ssh = Net::SSH.start(machine_ip, machine_username, :keys => [private_key_path])
    ssh.exec!(command).tap do
      ssh.close
    end
  end
end

World(SshHelpers)
