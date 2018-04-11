require 'spec_helper'

describe Conjur::Cast do
  let!(:object) {
    Object.new.tap do |obj|
      class << obj
        include Conjur::Cast
      end
    end
  }

  it 'String casts to itself' do
    expect(object.send(:cast_to_id, "foo")).to eq("foo")
  end
  it 'Id casts to to_s' do
    expect(object.send(:cast_to_id, "foo")).to eq("foo")
  end
  it 'Array casts via #join' do
    expect(object.send(:cast_to_id, [ "foo", "bar" ])).to eq("foo:bar")
  end
end
