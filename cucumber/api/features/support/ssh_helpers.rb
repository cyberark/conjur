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
end

World(SshHelpers)
