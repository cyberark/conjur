# spec/domain/domain_spec.rb
require 'spec_helper'

RSpec.describe(Domain) do
  let(:dummy_class) { Class.new { extend Domain } }

  describe '#root_pol_id_pattern' do
    it 'returns pattern for root' do
      expect(dummy_class.root_pol_id_pattern('root')).to eq('%(|/%)')
    end

    it 'returns pattern for non-root' do
      expect(dummy_class.root_pol_id_pattern('foo')).to eq('foo(|/%)')
    end
  end

  describe '#res_identifier' do
    it 'returns root for root identifier' do
      expect(dummy_class.res_identifier('/')).to eq('root')
    end

    it 'returns identifier for non-root' do
      expect(dummy_class.res_identifier('foo')).to eq('foo')
    end
  end

  describe '#domain_id' do
    it 'returns / for root' do
      expect(dummy_class.domain_id('root')).to eq('/')
    end

    it 'returns identifier for non-root' do
      expect(dummy_class.domain_id('foo')).to eq('/foo')
    end
  end

  describe '#to_identifier' do
    it 'returns identifier if parent is root' do
      expect(dummy_class.to_identifier('/', 'bar')).to eq('bar')
    end

    it 'joins parent and identifier if parent is not root' do
      expect(dummy_class.to_identifier('foo', 'bar')).to eq('foo/bar')
    end
  end

  describe '#full_id' do
    it 'joins account, type, and identifier with :' do
      expect(dummy_class.full_id('acc', 'type', 'id')).to eq('acc:type:id')
    end
  end

  describe '#account_of' do
    it 'returns account part' do
      expect(dummy_class.account_of('acc:type:id')).to eq('acc')
    end
  end

  describe '#kind' do
    it 'returns kind part' do
      expect(dummy_class.kind('acc:type:id')).to eq('type')
    end
  end

  describe '#res_name' do
    it 'returns last part of identifier' do
      expect(dummy_class.res_name('foo/bar/baz')).to eq('baz')
    end
  end

  describe '#parent_identifier' do
    it 'returns parent path' do
      expect(dummy_class.parent_of('foo/bar/baz')).to eq('foo/bar')
    end

    it 'returns / if no slash' do
      expect(dummy_class.parent_of('foo')).to eq('/')
    end
  end

  describe '#identifier' do
    it 'returns identifier part' do
      expect(dummy_class.identifier('acc:type:id')).to eq('id')
    end
  end

  describe '#root?' do
    it 'returns true for /' do
      expect(dummy_class.root?('/')).to be(true)
    end

    it 'returns true for root' do
      expect(dummy_class.root?('root')).to be(true)
    end

    it 'returns false for other values' do
      expect(dummy_class.root?('foo')).to be(false)
    end
  end
end
