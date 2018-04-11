require 'conjur/cidr'

describe Conjur::CIDR do
  def cidr addr
    Conjur::CIDR.validate addr
  end

  describe '.validate' do
    it 'rejects malformed addresses' do
      expect { Conjur::CIDR.validate '192.0.2.2/255.255.0.255' }.to raise_error ArgumentError
      expect { Conjur::CIDR.validate '192.0.2.2/0.255.0.0' }.to raise_error ArgumentError
      expect { Conjur::CIDR.validate '192.0.256.2' }.to raise_error ArgumentError
      expect { Conjur::CIDR.validate '::/:ffff:' }.to raise_error ArgumentError
    end
  end

  describe '#prefixlen' do
    it 'calculates prefix mask length' do
      expected = {
        '0.0.0.0/0' => 0,
        '192.0.2.0/24' => 24,
        '192.0.2.1' => 32,
        '192.0.2.0/255.255.255.0' => 24,
        '10.0.0.0/255.0.0.0' => 8,
        '1234::/42' => 42,
        '1234::/ffff::' => 16,
        '::/::' => 0,
      }
      expected.each do |addr, len|
        expect(Conjur::CIDR.validate(addr).prefixlen).to eq len
      end
    end
  end
end
