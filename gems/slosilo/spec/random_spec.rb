require 'spec_helper'

describe Slosilo::Random do
  subject { Slosilo::Random }
  let(:other_salt) { Slosilo::Random::salt }
  
  describe '#salt' do
    subject { super().salt }
    describe '#length' do
      subject { super().length }
      it { is_expected.to eq(32) }
    end
  end

  describe '#salt' do
    subject { super().salt }
    it { is_expected.not_to eq(other_salt) }
  end
end
