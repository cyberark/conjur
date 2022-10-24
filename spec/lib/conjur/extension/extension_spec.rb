# frozen_string_literal: true

require 'spec_helper'

require 'logger'
require 'conjur/extension/extension'

describe Conjur::Extension::Extension do
  # Test dependencies
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  let(:extensions_dir) { File.expand_path('../../../../fixtures/extensions', __FILE__) }
  let(:extensions) { [ 'test_extension' ] }
  let(:auto_load) { false }

  subject(:repository) do
    Conjur::Extension::Repository.new(
      extensions_dir: extensions_dir,
      logger: logger,
      extensions: extensions,
      auto_load: auto_load
    )
  end

  before do
    repository.load_extension('test_extension')
  end

  subject(:extension_set) do
    Conjur::Extension::Extension.new(
      implementations: [
        Conjur::Extension::Implementation.from_extension_class(
          TestExtensionA,
          logger: logger
        ),
        Conjur::Extension::Implementation.from_extension_class(
          TestExtensionB,
          logger: logger
        ),
        Conjur::Extension::Implementation.from_extension_class(
          TestExtensionC,
          logger: logger
        ),
        Conjur::Extension::Implementation.from_extension_class(
          TestExtensionE,
          logger: logger
        ),
        Conjur::Extension::Implementation.from_extension_class(
          TestExtensionF,
          logger: logger
        )
      ],
      logger: logger
    )
  end

  describe '#call' do
    it 'calls the method on classes that implement the method' do
      expect_any_instance_of(TestExtensionA).to receive(:on_callback)
      expect_any_instance_of(TestExtensionB).to receive(:on_callback)

      extension_set.call(:on_callback)
    end

    it "logs classes that don't respond to the message" do
      extension_set.call(:on_callback)
      expect(log_output.string).to include(
        "'TestExtensionC' doesn't respond to 'on_callback'"
      )
    end

    it "logs classes that don't have a usable method signatures" do
      extension_set.call(:on_callback)
      expect(log_output.string).to include(
        "Failed to call 'on_callback' on 'TestExtensionE': " \
        "Invalid target method parameters: required_param. " \
        "The method parameters must be empty or keyword args"
      )
    end

    it "logs classes that raise an exception when called" do
      extension_set.call(:on_callback)
      expect(log_output.string).to include(
        "Failed to call 'on_callback' on 'TestExtensionF': failure in the extension"
      )
    end
  end
end
