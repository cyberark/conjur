# frozen_string_literal: true
require 'spec_helper'

RSpec.describe('Util::TimeDelayedCache') do
  context "Callable is called only when needed" do
    let(:callable) {double("callable")}
    let(:block) { Proc.new { callable.call } }
    subject { Util::TimeExpiredCache.new(0.1, &block) }

    it "Multiple calls within the interval trigger the block only once" do
      allow(callable).to receive(:call).and_return('the result', 'other result')
      expect(callable).to receive(:call).once
      expect(subject.result).to eq('the result')
      expect(subject.result).to eq('the result')
      expect(subject.result).to eq('the result')
    end

    it "Multiple calls beside the interval trigger the block twice" do
      expect(callable).to receive(:call).twice.and_return('the result', 'other result')
      expect(subject.result).to eq('the result')
      sleep 0.2
      expect(subject.result).to eq('other result')
    end
  end
end
