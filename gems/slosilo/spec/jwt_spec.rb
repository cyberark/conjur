require 'spec_helper'

# (Mostly) integration tests for JWT token format
describe Slosilo::Key do
  include_context "with example key"

  describe '#issue_jwt' do
    it 'issues an JWT token with given claims' do
      allow(Time).to receive(:now) { DateTime.parse('2014-06-04 23:22:32 -0400').to_time }

      tok = key.issue_jwt sub: 'host/example', cidr: %w(fec0::/64)

      expect(tok).to be_frozen

      expect(tok.header).to eq \
        alg: 'conjur.org/slosilo/v2',
        kid: key_fingerprint
      expect(tok.claims).to eq \
        iat: 1401938552,
        sub: 'host/example',
        cidr: ['fec0::/64']

      expect(key.verify_signature tok.string_to_sign, tok.signature).to be_truthy
    end
  end
end

describe Slosilo::JWT do
  context "with a signed token" do
    let(:signature) { 'very signed, such alg' }
    subject(:token) { Slosilo::JWT.new test: "token" }
    before do
      allow(Time).to receive(:now) { DateTime.parse('2014-06-04 23:22:32 -0400').to_time }
      token.add_signature(alg: 'test-sig') { signature }
    end

    it 'allows conversion to JSON representation with #to_json' do
      json = JSON.load token.to_json
      expect(JSON.load Base64.urlsafe_decode64 json['protected']).to eq \
          'alg' => 'test-sig'
      expect(JSON.load Base64.urlsafe_decode64 json['payload']).to eq \
          'iat' => 1401938552, 'test' => 'token'
      expect(Base64.urlsafe_decode64 json['signature']).to eq signature
    end

    it 'allows conversion to compact representation with #to_s' do
      h, c, s = token.to_s.split '.'
      expect(JSON.load Base64.urlsafe_decode64 h).to eq \
          'alg' => 'test-sig'
      expect(JSON.load Base64.urlsafe_decode64 c).to eq \
          'iat' => 1401938552, 'test' => 'token'
      expect(Base64.urlsafe_decode64 s).to eq signature
    end
  end

  describe '#to_json' do
    it "passes any parameters" do
      token = Slosilo::JWT.new
      allow(token).to receive_messages \
          header: :header,
          claims: :claims,
          signature: :signature
      expect_any_instance_of(Hash).to receive(:to_json).with :testing
      expect(token.to_json :testing)
    end
  end

  describe '()' do
    include_context "with example key"

    it 'understands both serializations' do
      [COMPACT_TOKEN, JSON_TOKEN].each do |token|
        token = Slosilo::JWT token
        expect(token.header).to eq \
            'typ' => 'JWT',
            'alg' => 'conjur.org/slosilo/v2',
            'kid' => key_fingerprint
        expect(token.claims).to eq \
            'sub' => 'host/example',
            'iat' => 1401938552,
            'exp' => 1401938552 + 60*60,
            'cidr' => ['fec0::/64']
        expect(key.verify_signature token.string_to_sign, token.signature).to be_truthy
      end
    end

    it 'is a noop if already parsed' do
      token = Slosilo::JWT COMPACT_TOKEN
      expect(Slosilo::JWT token).to eq token
    end

    it 'raises ArgumentError on failure to convert' do
      expect { Slosilo::JWT "foo bar" }.to raise_error ArgumentError
      expect { Slosilo::JWT elite: 31337 }.to raise_error ArgumentError
      expect { Slosilo::JWT "foo.bar.xyzzy" }.to raise_error ArgumentError
    end
  end

  COMPACT_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGciOiJjb25qdXIub3JnL3Nsb3NpbG8vdjIiLCJraWQiOiIxMDdiZGI4NTAxYzQxOWZhZDJmZGIyMGI0NjdkNGQwYTYyYTE2YTk4YzM1ZjJkYTBlYjNiMWZmOTI5Nzk1YWQ5In0=.eyJzdWIiOiJob3N0L2V4YW1wbGUiLCJjaWRyIjpbImZlYzA6Oi82NCJdLCJleHAiOjE0MDE5NDIxNTIsImlhdCI6MTQwMTkzODU1Mn0=.qSxy6gx0DbiIc-Wz_vZhBsYi1SCkHhzxfMGPnnG6MTqjlzy7ntmlU2H92GKGoqCRo6AaNLA_C3hA42PeEarV5nMoTj8XJO_kwhrt2Db2OX4u83VS0_enoztWEZG5s45V0Lv71lVR530j4LD-hpqhm_f4VuISkeH84u0zX7s1zKOlniuZP-abCAHh0htTnrVz9wKG0VywkCUmWYyNNqC2h8PRf64SvCWcQ6VleHpjO-ms8OeTw4ZzRbzKMi0mL6eTmQlbT3PeBArUaS0pNJPg9zdDQaL2XDOofvQmj6Yy_8RA4eCt9HEfTYEdriVqK-_9QCspbGzFVn9GTWf51MRi5dngV9ItsDoG9ktDtqFuMttv7TcqjftsIHZXZsAZ175E".freeze

  JSON_TOKEN = "{\"protected\":\"eyJ0eXAiOiJKV1QiLCJhbGciOiJjb25qdXIub3JnL3Nsb3NpbG8vdjIiLCJraWQiOiIxMDdiZGI4NTAxYzQxOWZhZDJmZGIyMGI0NjdkNGQwYTYyYTE2YTk4YzM1ZjJkYTBlYjNiMWZmOTI5Nzk1YWQ5In0=\",\"payload\":\"eyJzdWIiOiJob3N0L2V4YW1wbGUiLCJjaWRyIjpbImZlYzA6Oi82NCJdLCJleHAiOjE0MDE5NDIxNTIsImlhdCI6MTQwMTkzODU1Mn0=\",\"signature\":\"qSxy6gx0DbiIc-Wz_vZhBsYi1SCkHhzxfMGPnnG6MTqjlzy7ntmlU2H92GKGoqCRo6AaNLA_C3hA42PeEarV5nMoTj8XJO_kwhrt2Db2OX4u83VS0_enoztWEZG5s45V0Lv71lVR530j4LD-hpqhm_f4VuISkeH84u0zX7s1zKOlniuZP-abCAHh0htTnrVz9wKG0VywkCUmWYyNNqC2h8PRf64SvCWcQ6VleHpjO-ms8OeTw4ZzRbzKMi0mL6eTmQlbT3PeBArUaS0pNJPg9zdDQaL2XDOofvQmj6Yy_8RA4eCt9HEfTYEdriVqK-_9QCspbGzFVn9GTWf51MRi5dngV9ItsDoG9ktDtqFuMttv7TcqjftsIHZXZsAZ175E\"}".freeze
end
