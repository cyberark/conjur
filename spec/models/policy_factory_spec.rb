# frozen_string_literal: true

require 'spec_helper'

shared_context "create policy factory role" do

  # 'let!' always runs before the example; 'let' is lazily evaluated.
  let!(:the_user) { 
    Role.create(role_id: "rspec:policy_factory:#{identifier}")
  }
end

describe PolicyFactory, :type => :model do
  include_context "create policy factory role"
  
  let(:identifier) { 'my-policy-factory' }

  it "policy role is required" do
    expect{ PolicyFactory.create(role_id: "") }.to raise_error(Sequel::ForeignKeyConstraintViolation, /(policy_factories_role_id_fkey)/)
  end

end
