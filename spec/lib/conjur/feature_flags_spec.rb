# frozen_string_literal: true

require 'logger'
require 'conjur/feature_flags'

describe Conjur::FeatureFlags::Features do
  describe '#enabled?' do
    let(:log_output) { StringIO.new }
    let(:logger) { Logger.new(log_output) }
    let(:feature_flags) do
      {
        foo: false,
        bar: false,
        baz: false
      }
    end

    let(:environment_settings) do
      {
        'FOO' => 'true',
        'CONJUR_FEATURE_BAR_ENABLED' => 'true',
        'CONJUR_FEATURE_BLANK_ENABLED' => 'true'
      }
    end

    subject do
      Conjur::FeatureFlags::Features.new(
        logger: logger,
        environment_settings: environment_settings,
        feature_flags: feature_flags
      )
    end

    context 'a feature is enabled by default' do
      let(:feature_flags) do
        {
          default_feature: true
        }
      end

      context 'with value `false`' do
        let(:environment_settings) do
          { 'CONJUR_FEATURE_DEFAULT_FEATURE_ENABLED' => 'false' }
        end

        it 'returns false' do
          expect(subject.enabled?(:default_feature)).to be(false)
        end
      end

      context 'with no value' do
        let(:environment_settings) { {} }

        it 'returns true' do
          expect(subject.enabled?(:default_feature)).to be(true)
        end
      end

      context 'with blank value' do
        let(:environment_settings) do
          { 'CONJUR_FEATURE_DEFAULT_FEATURE_ENABLED' => '' }
        end

        it 'returns true' do
          expect(subject.enabled?(:default_feature)).to be(true)
        end
      end

      context 'with value `Falsey`' do
        let(:environment_settings) do
          { 'CONJUR_FEATURE_BLANK_ENABLED' => 'Falsey' }
        end

        it 'returns true' do
          expect(subject.enabled?(:default_feature)).to be(true)
        end
      end
    end

    context 'a feature is enabled' do
      context 'and declared' do
        context 'with value `true`' do
          it 'returns true' do
            expect(subject.enabled?(:bar)).to be(true)
          end

          it 'logs the environment variable' do
            subject
            expect(log_output.string).to include('DEBUG')
            expect(log_output.string).to include('CONJUR_FEATURE_BAR_ENABLED')
          end
        end

        context 'with value `false`' do
          let(:environment_settings) do
            { 'CONJUR_FEATURE_BLANK_ENABLED' => 'false' }
          end
          let(:feature_flags) { { blank: false } }

          it 'returns false' do
            expect(subject.enabled?(:blank)).to be(false)
          end
        end

        context 'with value `Truthy`' do
          let(:environment_settings) do
            { 'CONJUR_FEATURE_BLANK_ENABLED' => 'Truthy' }
          end
          let(:feature_flags) { { blank: false } }

          it 'returns false' do
            expect(subject.enabled?(:blank)).to be(false)
          end
        end
      end

      context 'and not declared' do
        it 'returns false' do
          expect(subject.enabled?(:baz)).to be(false)
        end
      end
    end

    context 'argument is not a symbol' do
      it 'returns an error' do
        expect { subject.enabled?('bar') }.to raise_error(
          ArgumentError,
          'Feature name must be a symbol'
        )
      end
    end

    context 'argument is not a valid flag' do
      it 'returns an error' do
        expect { subject.enabled?(:blank) }.to raise_error(
          Conjur::FeatureFlags::Features::InvalidFeatureFlagError,
          'Feature flag not defined: blank'
        )
      end
    end
  end
end
