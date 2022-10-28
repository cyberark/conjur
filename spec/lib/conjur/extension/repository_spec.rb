# frozen_string_literal: true

require 'spec_helper'

require 'logger'
require 'conjur/extension/repository'

class TestExtensionClass; end

describe Conjur::Extension::Repository do
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  let(:extensions_dir) do
    File.expand_path('../../../../fixtures/extensions', __FILE__)
  end
  let(:extensions) { [ 'test_extension' ] }
  let(:auto_load) { true }
  let(:extension_cls_double) do
    double(Conjur::Extension::Extension)
  end

  before(:each) do
    # Reset the extension classes before each test
    Conjur::Extension::Repository.loaded_extensions = []
    Conjur::Extension::Repository.registered_extension_classes = []
  end

  subject(:repository) do
    Conjur::Extension::Repository.new(
      extensions_dir: extensions_dir,
      logger: logger,
      extensions: extensions,
      extension_cls: extension_cls_double,
      auto_load: auto_load
    )
  end

  describe 'self#register' do
    it 'adds the extension to the registered extensions collection' do
      Conjur::Extension::Repository.register(
        kind: :rspec,
        implementation_class: TestExtensionClass,
        logger: logger
      )

      expect(Conjur::Extension::Repository.registered_extension_classes)
        .to include(
          have_attributes(
            kind: :rspec,
            implementation_class: TestExtensionClass
          )
        )
    end

    it 'logs the registration' do
      Conjur::Extension::Repository.register(
        kind: :rspec,
        implementation_class: TestExtensionClass,
        logger: logger
      )

      expect(log_output.string)
        .to match(%r{Registering rspec extension: TestExtensionClass \(\/src\/conjur-server\/spec\/lib\/conjur\/extension/repository_spec.rb:\d+\)})
    end
  end

  describe '#loaded_extensions' do
    it 'returns the configured and available extensions' do
      expect(repository.class.loaded_extensions).to include('test_extension')
    end

    it 'logs that the extensions are loaded' do
      repository.class.loaded_extensions

      expect(log_output.string).to include('Loading extension: test_extension')
    end
  end

  describe '#load' do
    let(:auto_load) { false }

    it 'loads the given extension' do
      expect(repository.load_extension('test_extension')).to be(true)
      expect(repository.class.loaded_extensions).to include('test_extension')
    end

    it 'registers the classes in the extension' do
      repository.load_extension('test_extension')

      expect(repository.class.registered_extension_classes)
        .to include(
          have_attributes(
            kind: :rspec,
            implementation_class: TestExtensionA
          )
        )

      expect(repository.class.registered_extension_classes)
        .to include(
          have_attributes(
            kind: :rspec,
            implementation_class: TestExtensionB
          )
        )

      expect(repository.class.registered_extension_classes)
        .to include(
          have_attributes(
            kind: :rspec,
            implementation_class: TestExtensionC
          )
        )
    end

    it 'logs the loaded extension' do
      repository.load_extension('test_extension')
      expect(log_output.string).to include('Loading extension: test_extension')
    end

    context 'When the extension is already loaded' do
      before do
        repository.load_extension('test_extension')
      end

      it 'does not load an extension' do
        expect(repository.load_extension('test_extension')).to be(false)
      end

      it 'logs the failure' do
        repository.load_extension('test_extension')
        expect(log_output.string)
          .to include(
            "Extension 'test_extension' is already loaded"
          )
      end
    end

    context "When the extension's directory doesn't exist" do
      it 'does not load an extension' do
        expect(repository.load_extension('nonexistent_extension')).to be(false)
      end

      it 'logs the failure' do
        subject.load_extension('nonexistent_extension')
        expect(log_output.string)
          .to include(
            "Expected extension directory at " \
            "'/src/conjur-server/spec/fixtures/extensions/nonexistent_extension', " \
            "but this path does not exist or is not a directory"
          )
      end
    end

    context "When the extension's file doesn't exist" do
      it 'does not load an extension' do
        expect(repository.load_extension('no_file_extension')).to be(false)
      end

      it 'logs the failure' do
        repository.load_extension('no_file_extension')
        expect(log_output.string)
          .to include(
            "Expected extension file at " \
            "'/src/conjur-server/spec/fixtures/extensions/no_file_extension/no_file_extension.rb', " \
            "but this path does not exist or is not a file"
          )
      end
    end
  end

  describe '#extension' do
    before do
      # We need to ensure the repository is created first
      # so that the TestExtension classes are loaded.
      repository
    end

    it 'creates an extension object' do
      expect(extension_cls_double)
        .to receive(:new)
        .with(
          hash_including(
            implementations: [
              have_attributes(name: 'TestExtensionA'),
              have_attributes(name: 'TestExtensionB'),
              have_attributes(name: 'TestExtensionC'),
              # TestExtensionD is excluded because it can't be initialized
              have_attributes(name: 'TestExtensionE'),
              have_attributes(name: 'TestExtensionF')
            ]
          )
        )

      repository.extension(kind: :rspec)
    end
  end
end
