# frozen_string_literal: true
#
# Utility methods for performing actions in remote machines
#

require 'net/ssh'

module SshHelpers

  def run_command_in_machine(machine_ip, machine_username, machine_password, command)
    ssh = Net::SSH.start(machine_ip, machine_username, :password => machine_password)
    res = ssh.exec!(command)
    ssh.close
    res
  end
end

World(SshHelpers)
