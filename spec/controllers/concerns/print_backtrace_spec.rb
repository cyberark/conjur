# frozen_string_literal: true
require 'spec_helper'

describe PrintBacktrace do
  let(:logger) { double('logger') }
  let(:err) { double('err') }
  let(:backtrace) { ['conjur-class:23', "#{ENV['GEM_HOME']}/class:25", 'another-conjur-class:55'] }

  before do
    allow(err).to receive(:backtrace) { backtrace }
    allow(controller).to receive(:logger) { logger }
  end

  # Test controller class
  class Controller
    include PrintBacktrace
  end
  subject(:controller) { Controller.new }

  describe '#log_backtrace' do
    context 'when logger level is debug' do
      before do
        allow(logger).to receive(:level) { :debug }
      end

      it 'logs the full backtrace' do
        expect(logger).to receive(:error).with(backtrace.join("\n"))
        controller.send(:log_backtrace, err)
      end
    end

    context 'when logger level is info' do
      before do
        allow(logger).to receive(:level) { :info }
      end

      it 'logs only conjur lines in backtrace' do
        expect(logger).to receive(:error).with(%w[conjur-class:23 another-conjur-class:55].join("\n"))
        controller.send(:log_backtrace, err)
      end
    end
  end
end