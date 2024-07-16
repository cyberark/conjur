require 'spec_helper'

RSpec.describe(EffectivePolicy::ResPathing) do
  let(:pathing) { Class.new { include EffectivePolicy::ResPathing }.new }

  describe '#kind' do
    context 'when resource full id is provided' do
      it 'returns the kind of the resource' do
        expect(pathing.kind('account:kind:identifier')).to eq('kind')
      end
    end
  end

  describe '#policy?' do
    context 'when kind is "policy"' do
      it 'returns true' do
        expect(pathing.policy?('policy')).to be(true)
      end
    end

    context 'when kind is not "policy"' do
      it 'returns false' do
        expect(pathing.policy?('user')).to be(false)
      end
    end
  end

  describe '#user?' do
    context 'when kind is "user"' do
      it 'returns true' do
        expect(pathing.user?('user')).to be(true)
      end
    end

    context 'when kind is not "user"' do
      it 'returns false' do
        expect(pathing.user?('policy')).to be(false)
      end
    end
  end

  describe '#identifier' do
    it 'returns the identifier of the resource' do
      expect(pathing.identifier('account:kind:identifier')).to eq('identifier')
    end
  end

end
