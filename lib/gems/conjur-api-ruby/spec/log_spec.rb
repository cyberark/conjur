require 'spec_helper'
require 'io/grab'
require 'tempfile'

describe Conjur do
  describe '::log=' do
    before { @old_log = Conjur.log }
    let(:log) { double 'log' }
    it "creates the log with given type and makes it available" do
      allow(Conjur).to receive(:create_log).with(:param).and_return log
      Conjur::log = :param
      expect(Conjur::log).to eq(log)
    end
    after { Conjur.class_variable_set :@@log, @old_log }
  end

  describe '::create_log' do
    let(:log) { Conjur::create_log param }
    context "with 'stdout'" do
      let(:param) { 'stdout' }
      it "creates something which writes to STDOUT" do
        expect($stdout.grab { log << "foo" }).to eq('foo')
      end
    end

    context "with 'stderr'" do
      let(:param) { 'stderr' }
      it "creates something which writes to STDERR" do
        expect($stderr.grab { log << "foo" }).to eq('foo')
      end
    end

    context "with a filename" do
      let(:tempfile) { Tempfile.new 'spec' }
      let(:param) { tempfile.path }
      it "creates something which writes to the file" do
        log << "foo"
        expect(tempfile.read).to eq("foo")
      end
    end
  end
end
