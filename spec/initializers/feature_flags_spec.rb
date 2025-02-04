# frozen_string_literal: true

require 'spec_helper'

describe 'Feature flag initializer' do
  before do
    # Reload the initializer
    load Rails.root.join('config/initializers/feature_flags.rb')
  end

  let(:config) { Rails.application.config }

  # Helper method to let us set environment variables for a given spec
  def with_environment(key, value)
    previous_value = ENV[key]
    ENV[key] = value

    yield

    if previous_value
      ENV[key] = previous_value
    else
      ENV.delete(key)
    end
  end

  # Dynamic secrets feature
  it 'returns dynamic secrets disabled by defaults' do
    expect(config.feature_flags.enabled?(:dynamic_secrets)).to be(false)
  end

  context 'when the dynamic secrets is enabled with the environment variable' do
    around do |example|
      with_environment('CONJUR_FEATURE_DYNAMIC_SECRETS_ENABLED', 'true') do
        load Rails.root.join('config/initializers/feature_flags.rb')
        example.run
      end
    end

    it 'returns dynamic secrets enabled' do
      expect(config.feature_flags.enabled?(:dynamic_secrets)).to be(true)
    end
  end
end
