require 'spec_helper'

describe Conjur::ConjurConfig do
  let(:config_folder) { @config_folder || '/etc/conjur/config' }
  let(:config_file) { "#{config_folder}/conjur.yml" }

  let(:logger_double) { Logger.new(log_output) }
  let(:log_output) { StringIO.new }

  let(:config_args) { [] }
  let(:config_kwargs) { {} }

  subject do
    Conjur::ConjurConfig.new(
      *config_args,
      logger: logger_double,
      **config_kwargs
    )
  end

  it "uses default value if not set by environment variable or config file" do
    expect(subject.trusted_proxies).to eq([])
  end

  it "reports the attribute source as :defaults" do
    expect(subject.attribute_sources[:trusted_proxies]).
      to eq(:defaults)
  end

  context "with config file" do
    let(:config_file_contents) do
      <<~YAML
        trusted_proxies:
          - 1.2.3.4
      YAML
    end

    around do |example|
      with_temp_config_directory do |dir|
        @config_folder = dir

        # Create config file
        File.open(config_file, 'w') do |f|
          f.puts(config_file_contents)
        end

        # Run the example
        example.run
      end
    end

    it "logs that the config file exists" do
      subject
      expect(log_output.string).to include(
        "Loading Conjur config file: #{@config_folder}/conjur.yml"
      )
    end

    it "reads config value from file" do
      expect(subject.trusted_proxies).to eq(["1.2.3.4"])
    end

    it "reports the attribute source as :yml" do
      expect(subject.attribute_sources[:trusted_proxies]).
        to eq(:yml)
    end

    context "with a config file that is a string value" do
      let(:config_file_contents) do
        <<~YAML
          trusted_proxies
        YAML
      end

      it "fails validation" do
        expect { subject }.
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
        expect { subject }.
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
        expect { subject }.
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
        expect { subject }.
          to raise_error(Conjur::ConfigValidationError, /syntax error/)
      end
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
        expect(subject.trusted_proxies).to eq(["5.6.7.8"])
      end

      it "reports the attribute source as :env" do
        expect(subject.attribute_sources[:trusted_proxies]).
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
        expect(subject.trusted_proxies).
          to eq(["5.6.7.8", "9.10.11.12"])
      end
    end
  end

  describe "validation" do
    let(:config_kwargs) do
      {
        authenticators: "invalid-authn",
        trusted_proxies: "boop"
      }
    end

    it "raises error when validation fails" do
      expect { subject }.
        to raise_error(Conjur::ConfigValidationError)
    end

    it "includes the attributes that failed validation" do
      expect { subject }.
        to raise_error(/trusted_proxies/)
      expect { subject }.
        to raise_error(/authenticators/)
    end

    it "does not include the value that failed validation" do
      expect { subject }.
        to_not raise_error(/boop/)
      expect { subject }.
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
      expect(subject.trusted_proxies).to eq(["5.6.7.8"])
    end
  end

  describe "file and directory permissions" do
    context "when the directory doesn't exist" do
      around do |example|
        with_temp_config_directory do |dir|
          @config_folder = dir

          FileUtils.rm_rf(config_folder)

          # Run the example
          example.run
        end
      end

      it "logs a warning" do
        subject
        expect(log_output.string).to include(
          "Conjur config directory doesn't exist or has " \
          "insufficient permission to list it:"
        )
      end
    end

    context "when the directory lacks execute/search permissions" do
      around do |example|
        with_temp_config_directory do |dir|
          @config_folder = dir
          FileUtils.chmod(0444, @config_folder)

          # The tests run as root, so we must drop privilege to test permission
          # checks.
          as_user 'nobody' do
            example.run
          end
        end
      end

      it "logs a warning" do
        subject
        expect(log_output.string).to include(
          "Conjur config directory exists but is missing " \
          "search/execute permission required to list the config file:"
        )
      end
    end

    context "when the file doesn't exist" do
      around do |example|
        with_temp_config_directory do |dir|
          @config_folder = dir

          FileUtils.chmod(0111, config_folder)
          FileUtils.rm_rf(config_file)

          example.run
        end
      end

      it "logs a warning" do
        subject
        expect(log_output.string).to include(
          "Conjur config file doesn't exist or has insufficient " \
          "permission to list it:"
        )
      end
    end

    context "when the file lacks read permissions" do
      around do |example|
        with_temp_config_directory do |dir|
          @config_folder = dir
          FileUtils.chmod(0555, @config_folder)
          FileUtils.touch(config_file)
          FileUtils.chmod(0000, config_file)

          # The tests run as root, so we must drop privilege to test permission
          # checks.
          as_user 'nobody' do
            example.run
          end
        end
      end

      it "logs a warning" do
        # This last scenario will also raise an exception, but in this case, we
        # are only interested in the log output
        begin
          subject
        rescue
        end
        expect(log_output.string).to include(
          "Conjur config file exists but has insufficient " \
          "permission to read it:"
        )
      end
    end
  end
end

# Helper method for the config file tests to create a temporary directory for
# testing file and directory permissions behavior
def with_temp_config_directory
  # Configure a temporary config directory
  prev_config_dir = Anyway::Settings.default_config_path

  config_dir = Dir.mktmpdir
  Anyway::Settings.default_config_path = config_dir

  # Call the block
  yield config_dir
ensure
  # Resete the config directory
  Anyway::Settings.default_config_path = prev_config_dir

  # remove the temporary config directory
  FileUtils.rm_rf(config_folder)
end
