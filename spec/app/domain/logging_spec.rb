# spec/domain/logging/logging_spec.rb
require 'spec_helper'

class DummyClass
  include Logging

  def initialize(logger = nil)
    @logger = logger
  end

  def test_info
    log_info("info message")
  end

  def test_debug
    log_debug("debug message")
  end

  def test_error
    log_error("error message")
  end
end

RSpec.describe(Logging) do
  let(:logger) { instance_double(Logger, info?: true, debug?: true, info: nil, debug: nil, error: nil) }
  let(:dummy) { DummyClass.new(logger) }

  describe '#log_info' do
    it 'logs info with class and method name' do
      expect(logger).to receive(:info).with(/DummyClass#test_info: info message/)
      dummy.test_info
    end
  end

  describe '#log_debug' do
    it 'logs debug with class and method name' do
      expect(logger).to receive(:debug).with(/DummyClass#test_debug: debug message/)
      dummy.test_debug
    end
  end

  describe '#log_error' do
    it 'logs error with class and method name' do
      expect(logger).to receive(:error).with(/DummyClass#test_error: error message/)
      dummy.test_error
    end
  end
end
