require 'spec_helper'
require 'open3'

require 'commands/configuration/apply'

describe Commands::Configuration::Apply do
  let(:command_runner) { double(::Open3) }
  let(:process_manager) { double(::Process) }
  let(:output_stream) { double(::IO) }
  let(:apply_cmd) {
    Commands::Configuration::Apply.new(
      command_runner: command_runner,
      process_manager: process_manager,
      output_stream: output_stream
    )
  }

  context "Conjur process is running" do
    before do
      allow(command_runner).to receive(:capture2).and_return("123")
    end

    it "sends a 'USR1' signal to the Conjur process" do
      allow(output_stream).to receive(:puts)

      expect(process_manager).to receive(:kill).with('USR1', 123)
      apply_cmd.call
    end

    it "prints success message" do
      allow(process_manager).to receive(:kill).with('USR1', 123)

      expect(output_stream).to receive(:puts).with(
        "Conjur server reboot initiated. New configuration will be applied."
      )
      apply_cmd.call
    end
  end

  context "Conjur process is not running" do
    before do
      allow(command_runner).to receive(:capture2).and_return("0")
    end

    it "outputs an error" do
      expect { apply_cmd.call }.to raise_error(
        RuntimeError,
        "Conjur is not currently running, please start it with conjurctl server."
      )
    end
  end
end
