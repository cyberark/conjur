# frozen_string_literal: true

require 'spec_helper'

require 'logger'
require 'conjur/extension/implementation'

describe Conjur::Extension::Implementation do
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

  context "when the extension class cannot be initialized" do
    it "raise an error" do
      expect do
        Conjur::Extension::Implementation.from_extension_class(
          TestExtensionD
        )
      end
        .to raise_error(/Invalid target method parameters: _required_arg/)
    end
  end
end
