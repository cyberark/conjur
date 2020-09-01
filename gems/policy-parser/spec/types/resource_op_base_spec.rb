# frozen_string_literal: true

require 'spec_helper'

describe Conjur::PolicyParser::Types::ResourceOpBase do
  context "with multiple resources" do
    let(:resource) { %w(a b).map { |id| Types::Resource.new 'crispy', id } }
    describe '#subject_id' do
      it "returns an array of resource ids" do
        expect(op.subject_id).to eq %w(a b)
      end
    end
  end
  subject(:op) { TestOp.new }
  before { op.resource = resource }

  # Just bare bones op class for the test
  class TestOp < described_class
    attribute :role
    attribute :privilege, kind: :string, dsl_accessor: true
    attribute :resource, dsl_accessor: true
  end
  Types = Conjur::PolicyParser::Types
end
