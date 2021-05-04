# frozen_string_literal: true

require 'logger'
require './lib/conjur/feature_flags/features'

describe Conjur::FeatureFlags::Features do
  describe '#enabled?' do
    let(:log_output) { StringIO.new }
    let(:logger) { Logger.new(log_output) }

    let(:features) do
      Conjur::FeatureFlags::Features.new(
        logger: logger,
        environment_settings: {
          'FOO' => 'true',
          'CONJUR_FEATURE_BAR_ENABLED' => 'true',
          'CONJUR_FEATURE_BLANK_ENABLED' => 'true'
        },
        feature_flags: %i[foo bar baz]
      )
    end

    it 'returns false when a feature is not declared' do
      expect(features.enabled?(:bing)).to be(false)
    end

    it 'returns true when a feature is declared and enabled' do
      expect(features.enabled?(:bar)).to be(true)
    end

    it 'logs the environment variable when a feature is enabled' do
      features
      expect(log_output.string).to include('DEBUG')
      expect(log_output.string).to include('CONJUR_FEATURE_BAR_ENABLED')
    end

    it 'returns false when a feature is enabled but not declared' do
      expect(features.enabled?(:bing)).to be(false)
    end

    it 'returns an error unless arguement is a symbol' do
      expect { features.enabled?('bar') }.to raise_error(
        Conjur::FeatureFlags::InvalidArguement
      )
    end

    it 'returns false when a feature is enabled with a value other than `true`' do
      expect(Conjur::FeatureFlags::Features.new(
        logger: logger,
        environment_settings: {
          'CONJUR_FEATURE_BLANK_ENABLED' => 'false'
        },
        feature_flags: %i[blank]
      ).enabled?(:blank)).to be(false)

      expect(Conjur::FeatureFlags::Features.new(
        logger: logger,
        environment_settings: {
          'CONJUR_FEATURE_BLANK_ENABLED' => 'Truthy'
        },
        feature_flags: %i[blank]
      ).enabled?(:blank)).to be(false)
    end
  end
end
