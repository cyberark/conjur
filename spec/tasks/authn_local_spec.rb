# frozen_string_literal: true

require 'spec_helper'

Rails.application.load_tasks

describe 'authn_local.rake' do
  subject { Rake::Task['authn_local:run'] }

  after do
    # Allow the task to run again for subsequent tests
    subject.reenable
  end

  it 'runs the local authentication service' do
    expect(AuthnLocal).to receive(:run).with(
      socket: nil,
      queue_length: nil,
      timeout: nil
    )

    # Run the task
    subject.invoke
  end

  context 'with arguments' do
    it 'passes the argument values to the service' do
      expect(AuthnLocal).to receive(:run).with(
        socket: '/test',
        queue_length: '10',
        timeout: '15'
      )

      # Run the task
      subject.invoke('/test', '10', '15')
    end
  end

  context 'with environment variables' do
    around do |example|
      # Save any existing environment values
      original_socket = ENV['CONJUR_AUTHN_LOCAL_SOCKET']
      original_queue_length = ENV['CONJUR_AUTHN_LOCAL_QUEUE_LENGTH']
      original_timeout = ENV['CONJUR_AUTHN_LOCAL_TIMEOUT']

      # Add our test values to the environment
      ENV['CONJUR_AUTHN_LOCAL_SOCKET'] = '/env'
      ENV['CONJUR_AUTHN_LOCAL_QUEUE_LENGTH'] = '20'
      ENV['CONJUR_AUTHN_LOCAL_TIMEOUT'] = '30'

      example.run
    ensure
      # Restore the original values
      ENV['CONJUR_AUTHN_LOCAL_SOCKET'] = original_socket
      ENV['CONJUR_AUTHN_LOCAL_QUEUE_LENGTH'] = original_queue_length
      ENV['CONJUR_AUTHN_LOCAL_TIMEOUT'] = original_timeout
    end

    it 'passes the environment values to the service' do
      expect(AuthnLocal).to receive(:run).with(
        socket: '/env',
        queue_length: '20',
        timeout: '30'
      )

      # Run the task
      subject.invoke
    end

    context "and arguments" do
      it 'gives precedence to the argument values' do
        expect(AuthnLocal).to receive(:run).with(
          socket: '/test',
          queue_length: '10',
          timeout: '15'
        )

        # Run the task
        subject.invoke('/test', '10', '15')
      end
    end
  end
end
