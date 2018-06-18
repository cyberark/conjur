require 'spec_helper'

require 'util/struct'

describe Util::Struct do
  subject(:struct) { Class.new(Util::Struct) { field :req, opt: 42 } }

  it 'allows declaring optional fields' do
    expect(struct.new(req: 44)).to have_attributes req: 44, opt: 42
    expect(struct.new(req: 44, opt: 0)).to have_attributes req: 44, opt: 0
  end

  it 'inherits fields from superclass' do
    child = Class.new(struct) { field :new }
    expect(child.new(req: 44, new: :old)).to have_attributes \
      req: 44, opt: 42, new: :old
  end

  describe '.abstract_field' do
    let(:struct) { Class.new(Util::Struct) { abstract_field :dyn } }

    it 'can be used with a string' do
      with_string = Class.new(struct) { dyn 'testing' }
      expect(with_string.new).to have_attributes dyn: 'testing'
    end

    it 'can be used with a block' do
      with_block = Class.new(struct) do
        field :param
        dyn { "param is #{param}" }
      end
      expect(with_block.new(param: 42)).to have_attributes dyn: "param is 42"
    end

    it "does not break inspection even when it's to_s" do
      struct = Class.new(Util::Struct) { abstract_field :to_s }
      child = Class.new(struct) { to_s "hello world" }
      expect { child.new.inspect }.not_to raise_error
    end
  end
end
