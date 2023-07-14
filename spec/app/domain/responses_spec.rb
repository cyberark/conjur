# frozen_string_literal: true

require 'spec_helper'

describe SuccessResponse do
  context 'when initialized' do
    let(:success) { SuccessResponse.new('foo') }

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
  end
end

describe FailureResponse do
  context 'when initialized with only a message' do
    let(:failure) { FailureResponse.new('bar') }

    describe '.message' do
      it 'is the message set in the initializer' do
        expect(failure.message).to eq('bar')
      end
    end

    describe '.level' do
      it 'is at `warn` level by default' do
        expect(failure.level).to eq(:warn)
      end
    end

    describe '.success?' do
      it 'is false' do
        expect(failure.success?).to be(false)
      end
    end
  end

  context 'when initialized with all options' do
    let(:message) { 'baz' }
    let(:initialize_arguments) { { level: :debug, status: :forbidden } }
    let(:failure) { FailureResponse.new(message, **initialize_arguments) }

    describe '.message' do
      context 'when message is set in the initializer' do
        context 'when it is a string' do
          it "is returned as a hash with the key 'message'" do
            expect(failure.message).to eq('baz')
          end
        end
        context 'when it is a hash' do
          let(:message) { { foo: 'baz' } }
          it 'is returned as a hash' do
            expect(failure.message).to eq({ foo: 'baz' })
          end
        end
        context 'when it is an array' do
          let(:message) { [{ foo: 'baz' }] }
          it 'is returned as an array' do
            expect(failure.message).to eq([{ foo: 'baz' }])
          end
        end
      end
    end

    describe '.to_s' do
      context 'when message is a string' do
        let(:message) { 'baz' }
        it 'returns the expected string' do
          expect(failure.to_s).to eq('baz')
        end
      end
      context 'when message is a hash' do
        let(:message) { { foo: 'baz' } }
        it 'returns the expected string' do
          expect(failure.to_s).to eq('{:foo=>"baz"}')
        end
      end
      context 'when message is an array' do
        let(:message) { ['baz'] }
        it 'returns the expected string' do
          expect(failure.to_s).to eq('["baz"]')
        end
      end
    end

    describe '.level' do
      context 'when level is a symbol' do
        let(:initialize_arguments) { { level: :warn, status: :forbidden } }
        it 'is the level set in the initializer' do
          expect(failure.level).to eq(:warn)
        end
      end

      context 'when level is a string' do
        let(:initialize_arguments) { { level: 'warn', status: :forbidden } }
        it 'is the level set in the initializer' do
          expect(failure.level).to eq(:warn)
        end
      end
    end

    describe '.status' do
      context 'when set in initializer' do
        it 'is the message set in the initializer' do
          expect(failure.status).to eq(:forbidden)
        end
      end
      context 'when set by default' do
        let(:initialize_arguments) { {} }
        it 'is the default option' do
          expect(failure.status).to eq(:unauthorized)
        end
      end
    end

    describe '.success?' do
      it 'is false' do
        expect(failure.success?).to be(false)
      end
    end
  end
end
