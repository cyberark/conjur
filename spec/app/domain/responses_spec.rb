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
        expect(failure.message).to eq({ message: 'bar' })
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
            expect(failure.message).to eq({ message: 'baz' })
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

    describe '.to_h' do
      let(:message) { 'baz' }
      context 'when default status is used' do
        it 'returns an error and code' do
          expect(failure.to_h).to eq({ code: 403, error: { message: 'baz' } })
        end
      end
      context 'when defined status is used' do
        let(:initialize_arguments) { { level: :debug, status: :bad_request } }
        it 'returns an error and code' do
          expect(failure.to_h).to eq({ code: 400, error: { message: 'baz' } })
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
