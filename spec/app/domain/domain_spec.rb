# spec/domain/domain_spec.rb
require 'spec_helper'

RSpec.describe(Domain) do
  let(:domain) { Class.new { extend Domain } }

  describe '#root_pol_id_pattern' do
    it 'returns pattern for root' do
      expect(domain.root_pol_id_pattern('root')).to eq('%(|/%)')
    end

    it 'returns pattern for non-root' do
      expect(domain.root_pol_id_pattern('foo')).to eq('foo(|/%)')
    end
  end

  describe '#res_identifier' do
    it 'returns root for root identifier' do
      expect(domain.res_identifier('/')).to eq('root')
    end

    it 'returns identifier for non-root' do
      expect(domain.res_identifier('foo')).to eq('foo')
    end
  end

  describe '#domain_id' do
    it 'returns / for root' do
      expect(domain.domain_id('root')).to eq('/')
    end

    it 'returns identifier for non-root' do
      expect(domain.domain_id('foo')).to eq('/foo')
    end
  end

  describe '#to_identifier' do
    it 'returns identifier if parent is root' do
      expect(domain.to_identifier('/', 'bar')).to eq('bar')
    end

    it 'joins parent and identifier if parent is not root' do
      expect(domain.to_identifier('foo', 'bar')).to eq('foo/bar')
    end
  end

  describe '#full_id' do
    it 'joins account, type, and identifier with :' do
      expect(domain.full_id('acc', 'type', 'id')).to eq('acc:type:id')
    end
  end

  describe '#account_of' do
    it 'returns account part' do
      expect(domain.account_of('acc:type:id')).to eq('acc')
    end
  end

  describe '#kind' do
    it 'returns kind part' do
      expect(domain.kind('acc:type:id')).to eq('type')
    end
  end

  describe '#res_name' do
    it 'returns last part of identifier' do
      expect(domain.res_name('foo/bar/baz')).to eq('baz')
    end
  end

  describe '#parent_identifier' do
    it 'returns parent path' do
      expect(domain.parent_of('foo/bar/baz')).to eq('foo/bar')
    end

    it 'returns / if no slash' do
      expect(domain.parent_of('foo')).to eq('/')
    end
  end

  describe '#identifier' do
    it 'returns identifier part' do
      expect(domain.identifier('acc:type:id')).to eq('id')
    end
  end

  describe '#root?' do
    it 'returns true for /' do
      expect(domain.root?('/')).to be(true)
    end

    it 'returns true for root' do
      expect(domain.root?('root')).to be(true)
    end

    it 'returns false for other values' do
      expect(domain.root?('foo')).to be(false)
    end
  end

  describe '#policy?' do
    context 'when kind is "policy"' do
      it 'returns true' do
        expect(domain.policy?('policy')).to be(true)
      end
    end

    context 'when kind is not "policy"' do
      it 'returns false' do
        expect(domain.policy?('user')).to be(false)
      end
    end
  end

  describe '#user?' do
    context 'when kind is "user"' do
      it 'returns true' do
        expect(domain.user?('user')).to be(true)
      end
    end

    context 'when kind is not "user"' do
      it 'returns false' do
        expect(domain.user?('policy')).to be(false)
      end
    end
  end
end
