# frozen_string_literal: true

require 'spec_helper'

describe Schemata do
  include Schemata::Helper

  def db
    Sequel::Model.db
  end

  before do
    db.search_path = search_path
  end
  after do
    restore_search_path
  end

  let(:schemata) { Schemata.new }

  describe "with search path $user, publc" do
    let(:search_path) { %i[$user public] }
    describe "search_path" do
      specify { expect(schemata.search_path).to eq(search_path) }
    end
    describe "primary_schema" do
      specify { expect(schemata.primary_schema).to eq(:public) }
    end
  end
  describe "with search path conjur_%rand, publc" do
    let(:rand) { SecureRandom.hex(5) }
    let(:search_path) { [ "conjur_#{rand}", "public" ] }
    before do
      db["CREATE SCHEMA #{search_path.first}"].update
    end
    after do
      db["DROP SCHEMA #{search_path.first}"].update
    end
    describe "search_path" do
      specify { expect(schemata.search_path).to eq(search_path.map(&:to_sym)) }
    end
    describe "primary_schema" do
      specify { expect(schemata.primary_schema).to eq(search_path.first.to_sym) }
    end
  end
end
