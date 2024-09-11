require 'spec_helper'

describe Util::V2Helpers do
  context 'When translating from v1 syntax to v2 syntax' do
    it 'translates variable to secret' do
      expect(Util::V2Helpers.translate_kind('variable')).to eq('secret')
    end
    it 'translates host to workload' do
      expect(Util::V2Helpers.translate_kind('host')).to eq('workload')
    end
  end
end
