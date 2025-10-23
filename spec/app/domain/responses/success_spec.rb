# frozen_string_literal: true

require 'spec_helper'

describe Responses::Success do
  context 'when initialized' do
    let(:success) { Responses::Success.new('foo') }

    describe '.result' do
      it 'is the message set in the initializer' do
        expect(success.result).to eq('foo')
      end
    end

    describe '.success?' do
      it 'is true' do
        expect(success.success?).to be(true)
      end
    end

    describe '.bind' do
      it 'binds this response message to the next operation' do
        expect(success.bind { |response| "#{response}-bar"}).to eq('foo-bar')
      end
    end
  end
end
