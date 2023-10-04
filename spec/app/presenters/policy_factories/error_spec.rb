# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Presenter::PolicyFactories::Error) do
  subject do
    Presenter::PolicyFactories::Error.new(response: response)
  end

  describe '.present' do
    context 'when response message is a string' do
      let(:response) { FailureResponse.new('foo-bar') }
      it 'returns the expected value' do
        expect(subject.present).to eq({
          code: 401,
          error: { message: 'foo-bar' }
        })
      end
    end
    context 'when response message is a hash' do
      let(:response) { FailureResponse.new({ message: 'foo-bar' }) }
      it 'returns the expected value' do
        expect(subject.present).to eq({
          code: 401,
          error: { message: 'foo-bar' }
        })
      end
    end
    context 'when response message is an array' do
      let(:response) { FailureResponse.new([{ message: 'foo-bar' }]) }
      it 'returns the expected value' do
        expect(subject.present).to eq({
          code: 401,
          error: [{ message: 'foo-bar' }]
        })
      end
    end

  end
end
