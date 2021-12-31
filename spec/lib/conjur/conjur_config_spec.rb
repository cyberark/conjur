require 'spec_helper'

describe Conjur::ConjurConfig do
  it "uses default value if not set by environment variable or config file" do
    expect(Conjur::ConjurConfig.new.trusted_proxies).to eq([])
    expect(Conjur::ConjurConfig.new.tracing_enabled).to eq(false)
  end

  it "reports the attribute source as :defaults" do
    expect(Conjur::ConjurConfig.new.attribute_sources[:trusted_proxies]).
      to eq(:defaults)
      expect(Conjur::ConjurConfig.new.attribute_sources[:tracing_enabled]).
      to eq(:defaults)
  end

  context "with config file" do
    let(:config_folder) { "/etc/conjur/config" }
    let(:config_file) { "#{config_folder}/conjur.yml" }

    let(:config_file_contents) do
      <<~YAML
        trusted_proxies:
          - 1.2.3.4
      YAML
    end

    before do
      FileUtils.mkdir_p(config_folder)

      File.open(config_file, 'w') do |f|
        f.puts(config_file_contents)
      end
    end

    after do
      FileUtils.remove_dir(config_folder)
    end

    it "reads config value from file" do
      expect(Conjur::ConjurConfig.new.trusted_proxies).to eq(["1.2.3.4"])
    end

    it "reports the attribute source as :yml" do
      expect(Conjur::ConjurConfig.new.attribute_sources[:trusted_proxies]).
        to eq(:yml)
    end

    context "with a config file that is a string value" do
      let(:config_file_contents) do
        <<~YAML
          trusted_proxies
        YAML
      end

      it "fails validation" do
        expect { Conjur::ConjurConfig.new }.
          to raise_error(Conjur::ConfigValidationError)
      end
    end

    context "with a config file that is an array value" do
      let(:config_file_contents) do
        <<~YAML
          - trusted_proxies
          - authenticators
        YAML
      end

      it "fails validation" do
        expect { Conjur::ConjurConfig.new }.
          to raise_error(Conjur::ConfigValidationError)
      end
    end

    context "with a config file that is a numeric value" do
      let(:config_file_contents) do
        <<~YAML
          10
        YAML
      end

      it "fails validation" do
        expect { Conjur::ConjurConfig.new }.
          to raise_error(Conjur::ConfigValidationError)
      end
    end

    context "with a config file that is invalid YAML" do
      let(:config_file_contents) do
        <<~YAML
          [
        YAML
      end

      it "fails validation" do
        expect { Conjur::ConjurConfig.new }.
          to raise_error(Conjur::ConfigValidationError, /syntax error/)
      end
    end

    context "with prefixed env var" do
      before do
        ENV['CONJUR_TRUSTED_PROXIES'] = "5.6.7.8"
        ENV['CONJUR_TRACING_ENABLED'] = "true"

        # Anyway Config caches prefixed env vars at the class level so we must
        # clear the cache to have it pick up the new var with a reload.
        Anyway.env.clear
      end

      after do
        ENV.delete('CONJUR_TRUSTED_PROXIES')
        ENV.delete('CONJUR_TRACING_ENABLED')
        # Clear again to make sure we don't affect future tests.
        Anyway.env.clear
      end

      it "overrides the config file value" do
        expect(Conjur::ConjurConfig.new.trusted_proxies).to eq(["5.6.7.8"])
        expect(Conjur::ConjurConfig.new.tracing_enabled).to eq(true)
      end

      it "reports the attribute source as :env" do
        expect(Conjur::ConjurConfig.new.attribute_sources[:trusted_proxies]).
          to eq(:env)
        expect(Conjur::ConjurConfig.new.attribute_sources[:tracing_enabled]).
          to eq(:env)
      end
    end

    context "with multiple values" do
      before do
        ENV['CONJUR_TRUSTED_PROXIES'] = "5.6.7.8,9.10.11.12"

        # Anyway Config caches prefixed env vars at the class level so we must
        # clear the cache to have it pick up the new var with a reload.
        Anyway.env.clear
      end

      after do
        ENV.delete('CONJUR_TRUSTED_PROXIES')

        # Clear again to make sure we don't affect future tests.
        Anyway.env.clear
      end

      it "overrides the config file value" do
        expect(Conjur::ConjurConfig.new.trusted_proxies).
          to eq(["5.6.7.8", "9.10.11.12"])
      end
    end
  end

  describe "validation" do
    let(:invalid_config) {
      Conjur::ConjurConfig.new(
        authenticators: "invalid-authn", trusted_proxies: "boop"
      )
    }

    it "raises error when validation fails" do
      expect { invalid_config }.
        to raise_error(Conjur::ConfigValidationError)
    end

    it "includes the attributes that failed validation" do
      expect { invalid_config }.
        to raise_error(/trusted_proxies/)
      expect { invalid_config }.
        to raise_error(/authenticators/)
    end

    it "does not include the value that failed validation" do
      expect { invalid_config }.
        to_not raise_error(/boop/)
      expect { invalid_config }.
        to_not raise_error(/invalid-authn/)
    end
  end

  describe "trusted proxies backwards compatibility" do
    before do
      ENV['TRUSTED_PROXIES'] = "5.6.7.8"

      # Anyway Config determines default values when the config class (not an
      # instance) is first loaded. This is the only way I could find to simulate
      # TRUSTED_PROXIES being set when the class is first loaded.
      load "#{Rails.root}/lib/conjur/conjur_config.rb"
    end

    after do
      ENV.delete('TRUSTED_PROXIES')

      # Load again to clear default
      load "#{Rails.root}/lib/conjur/conjur_config.rb"

      # Anyway Config caches prefixed env vars at the class level so we must
      # clear the cache to have it pick up the new var with a reload.
      Anyway.env.clear
    end

    it "reads value from TRUSTED_PROXIES env var" do
      expect(Conjur::ConjurConfig.new.trusted_proxies).to eq(["5.6.7.8"])
    end
  end
end
