require 'spec_helper'

describe Conjur::ConjurConfig do
  it "uses default value if not set by environment variable or config file" do
    expect(Conjur::ConjurConfig.new.trusted_proxies).to eq([])
  end

  it "reports the attribute source as :defaults" do
    expect(Conjur::ConjurConfig.new.attribute_sources[:trusted_proxies]).
      to eq(:defaults)
  end

  context "with config file" do
    let(:config_folder) { "/etc/conjur/config" }
    let(:config_file) { "#{config_folder}/conjur.yml" }

    before do
      FileUtils.mkdir_p(config_folder)

      File.open(config_file, 'w') do |f|
        f.puts("trusted_proxies:")
        f.puts("  - 1.2.3.4")
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

    context "with prefixed env var" do
      before do
        ENV['CONJUR_TRUSTED_PROXIES'] = "5.6.7.8"

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
        expect(Conjur::ConjurConfig.new.trusted_proxies).to eq(["5.6.7.8"])
      end

      it "reports the attribute source as :env" do
        expect(Conjur::ConjurConfig.new.attribute_sources[:trusted_proxies]).
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
      Conjur::ConjurConfig.new(trusted_proxies: "boop")
    }

    it "raises error when validation fails" do
      expect { invalid_config }.
        to raise_error(Errors::Conjur::InvalidConfigValues)
    end

    it "includes the attribute that failed validation" do
      expect { invalid_config }.
        to raise_error(/trusted_proxies/)
    end

    it "does not include the value that failed validation" do
      expect { invalid_config }.
        to_not raise_error(/boop/)
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

      # Anyway Config caches prefixed env vars at the class level so we must
      # clear the cache to have it pick up the new var with a reload.
      Anyway.env.clear
    end

    it "reads value from TRUSTED_PROXIES env var" do
      expect(Conjur::ConjurConfig.new.trusted_proxies).to eq(["5.6.7.8"])
    end
  end
end
