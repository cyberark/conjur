# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnOidc::V2::DataObjects::AuthenticatorContract) do
  subject { Authentication::AuthnJwt::V2::DataObjects::AuthenticatorContract.new.call(**params) }
  let(:default_args) { { account: 'foo', service_id: 'bar' } }
  let(:public_keys) { '{"type":"jwks","value":{"keys":[{}]}}' }

  context 'when more than one of the following are set: jwks_uri, public_keys, and provider_uri' do
    context 'when jwks_uri and public_keys are set' do
      # TODO: this error message doesn't make sense...
      let(:params) { default_args.merge(jwks_uri: 'foo', public_keys: public_keys) }
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          'CONJ00154E Invalid signing key settings: jwks-uri and provider-uri cannot be defined simultaneously'
        )
      end
    end
    context 'when jwks_uri and provider_uri are set' do
      let(:params) { default_args.merge(jwks_uri: 'foo', provider_uri: public_keys) }
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          'CONJ00154E Invalid signing key settings: jwks-uri and provider-uri cannot be defined simultaneously'
        )
      end
    end
    context 'when provider_uri and public_keys are set' do
      # TODO: this error message doesn't make sense...
      let(:params) { default_args.merge(provider_uri: 'foo', public_keys: public_keys) }
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          'CONJ00154E Invalid signing key settings: jwks-uri and provider-uri cannot be defined simultaneously'
        )
      end
    end
  end

  context 'when public_keys are defined' do
    context 'when issuer is missing' do
      let(:params) { default_args.merge(public_keys: public_keys) }
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          'CONJ00037E Missing value for resource: foo:variable:conjur/authn-jwt/bar/issuer'
        )
      end
    end
    context 'when issuer is empty' do
      let(:params) { default_args.merge(public_keys: public_keys, issuer: '') }
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          'CONJ00037E Missing value for resource: foo:variable:conjur/authn-jwt/bar/issuer'
        )
      end
    end
    context 'when public keys are malformed' do
      # Public Keys are pretty finicky. They are required to be:
      # - valid JSON
      # - includes 'type' and 'value' keys
      # - type must be 'jwks'
      # - value needs to have a 'keys' value with a form like:
      #   "keys": [{
      #   	"e": "AQAB",
      #   	"kty": "RSA",
      #   	"n": "ugwppRMuZ0uROdbPewhNUS4219DlBiwXaZOje-PMXdfXRw8umH7IJ9bCIya6ayolap0YWyFSDTTGStRBIbmdY9HKJ25XqkRrVHlUAfBBS_K7zlfoF3wMxmc_sDyXBUET7R3VaDO6A1CuGYwQ5Shj-bSJa8RmOH0OlwSlhr0fKME",
      #   	"kid": "FlpP5WEr5YFZtEYbGH6E-JtWOHk-edj4hPiGOvnU1fY"
      #   }]
      context 'when public keys are invalid JSON' do
        let(:params) { default_args.merge(public_keys: 'bar', issuer: 'foo') }
        it 'is unsuccessful' do
          expect(subject.success?).to be(false)
          expect(subject.errors.first.text).to eq(
            "CONJ00153E 'bar' is not valid JSON"
          )
        end
      end
      context 'when attributes are invalid' do
        context 'when value key is missing' do
          let(:params) { default_args.merge(public_keys: '{"type":"jwks"}', issuer: 'foo') }
          it 'is unsuccessful' do
            expect(subject.success?).to be(false)
            expect(subject.errors.first.text).to eq(
              "CONJ00120E Failed to parse 'public-keys': Type can't be blank, Value can't be blank, and Type '' is not a valid public-keys type. Valid types are: jwks"
            )
          end
        end
        context 'when type key is missing' do
          let(:params) { default_args.merge(public_keys: '{"value":{"keys":[]}}', issuer: 'foo') }
          it 'is unsuccessful' do
            expect(subject.success?).to be(false)
            expect(subject.errors.first.text).to eq(
              "CONJ00120E Failed to parse 'public-keys': Type can't be blank, Value can't be blank, and Type '' is not a valid public-keys type. Valid types are: jwks"
            )
          end
        end
        context 'when type key is not `jwks`' do
          let(:params) { default_args.merge(public_keys: '{"type":"foo","value":{"keys":[]}}', issuer: 'foo') }
          it 'is unsuccessful' do
            expect(subject.success?).to be(false)
            expect(subject.errors.first.text).to eq(
              "CONJ00120E Failed to parse 'public-keys': Type can't be blank, Value can't be blank, and Type '' is not a valid public-keys type. Valid types are: jwks"
            )
          end
        end
        context 'when "value" is missing the key "keys"' do
          context 'when value is empty' do
            let(:params) { default_args.merge(public_keys: '{"type":"jwks","value":""}', issuer: 'foo') }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.errors.first.text).to eq(
                "CONJ00120E Failed to parse 'public-keys': Value must include the name/value pair 'keys', which is an array of valid JWKS public keys"
              )
            end
          end
          context 'when value is missing "keys" key' do
            let(:params) { default_args.merge(public_keys: '{"type":"jwks","value":{"key":""}}', issuer: 'foo') }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.errors.first.text).to eq(
                "CONJ00120E Failed to parse 'public-keys': Value must include the name/value pair 'keys', which is an array of valid JWKS public keys"
              )
            end
          end
          context 'when value "keys" is not an array' do
            let(:params) { default_args.merge(public_keys: '{"type":"jwks","value":{"keys":{}}}', issuer: 'foo') }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.errors.first.text).to eq(
                "CONJ00120E Failed to parse 'public-keys': Value must include the name/value pair 'keys', which is an array of valid JWKS public keys"
              )
            end
          end
          context 'when value "keys" is an empty array' do
            let(:params) { default_args.merge(public_keys: '{"type":"jwks","value":{"keys":[]}}', issuer: 'foo') }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.errors.first.text).to eq(
                "CONJ00120E Failed to parse 'public-keys': Value must include the name/value pair 'keys', which is an array of valid JWKS public keys"
              )
            end
          end
        end
      end
    end
  end

  %i[jwks_uri public_keys provider_uri].each do |attribute|
    context "when #{attribute} is set but has no value" do
      let(:params) { default_args.merge(attribute => '') }
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00037E Missing value for resource: foo:variable:conjur/authn-jwt/bar/#{attribute.to_s.dasherize}"
        )
      end
    end
  end

  %i[token_app_property identity_path issuer enforced_claims claim_aliases audience ca_cert].each do |attribute|
    context "when #{attribute} is set but has no value" do
      let(:params) { default_args.merge(attribute => '', jwks_uri: 'foo') }
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00037E Missing value for resource: foo:variable:conjur/authn-jwt/bar/#{attribute.to_s.dasherize}"
        )
      end
    end
  end

  context 'when one of the following are set: jwks_uri, public_keys, and provider_uri' do
    %i[jwks_uri public_keys provider_uri].each do |key|
      let(:params) { default_args.merge(key => 'foo') }
      it 'is successful' do
        expect(subject.success?).to be(true)
      end
    end
  end

  context 'when jwks_uri, public_keys, and provider_uri are all missing' do
    let(:params) { default_args }
    it 'is unsuccessful' do
      expect(subject.success?).to be(false)
      expect(subject.errors.first.text).to eq(
        'CONJ00154E Invalid signing key settings: One of the following must be defined: jwks-uri, public-keys, or provider-uri'
      )
    end
  end

  context 'token_app_property' do
    let(:params) { default_args.merge(token_app_property: token_app_property, jwks_uri: 'foo') }
    let(:token_app_property) { 'foo-bar/Baz-2_bing.baz'}
    context 'with valid characters' do
      it 'is successful' do
        expect(subject.success?).to be(true)
      end
    end
    context 'with invalid-characters' do
      let(:token_app_property) { 'f?o-bar/baz-2'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00117E Failed to parse 'token-app-property' value. Error: 'token-app-property can only contain alpha-numeric characters, '-', '_', '/', and '.''"
        )
      end
    end
    context 'with double slashes' do
      let(:token_app_property) { 'foo-bar//baz-2'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00117E Failed to parse 'token-app-property' value. Error: 'token-app-property includes `//`'"
        )
      end
    end
  end

  context 'enforced_claims' do
    let(:params) { default_args.merge(enforced_claims: enforced_claims, jwks_uri: 'foo') }
    let(:enforced_claims) { 'foo-bar, Baz-2_bi/ng.baz'}
    context 'with valid characters' do
      it 'is successful' do
        expect(subject.success?).to be(true)
      end
    end
    context 'with invalid-characters' do
      let(:enforced_claims) { 'f?o-bar/b, az-2'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00104E Failed to validate claim: claim name 'f?o-bar/b' does not match regular expression: '[a-zA-Z0-9/-_.]+'."
        )
      end
    end
    context 'with claims in reserved claim list' do
      let(:contract) { Authentication::AuthnJwt::V2::DataObjects::AuthenticatorContract.new }
      %w[iss exp nbf iat jti aud].each do |reserved_claim|
        enforced_claims = "foo-bar/b, #{reserved_claim}"
        it 'is unsuccessful' do
          result = contract.call(**default_args.merge(enforced_claims: enforced_claims, jwks_uri: 'foo'))
          expect(result.success?).to be(false)
          expect(result.errors.first.text).to eq(
            "CONJ00105E Failed to validate claim: claim name '#{reserved_claim}' is in denylist '[\"iss\", \"exp\", \"nbf\", \"iat\", \"jti\", \"aud\"]'"
          )
        end
      end
    end
  end

  context 'claim_aliases' do
    let(:params) { default_args.merge(claim_aliases: claim_aliases, jwks_uri: 'foo') }
    let(:claim_aliases) { 'foo-bar:baz/bing, Baz-2_bi:ng.baz'}
    context 'with bad characters in alias' do
      let(:claim_aliases) { 'f?o-bar:az-2/b'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00104E Failed to validate claim: claim name 'f?o-bar' does not match regular expression: '[a-zA-Z0-9\\-_\\.]+'."
        )
      end
    end
    context 'with bad characters in alias target' do
      let(:claim_aliases) { 'foo-bar:az-2/b?s'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00104E Failed to validate claim: claim name 'az-2/b?s' does not match regular expression: '[a-zA-Z0-9/-_.]+'."
        )
      end
    end
    context 'with double slashes in alias' do
      # TODO: This error message makes no sense
      let(:claim_aliases) { 'foo//bar:az-2/b'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00114E Failed to parse claim aliases: the claim alias name 'foo//bar' contains '/'."
        )
      end
    end
    context 'when claim alias is defined multiple times' do
      let(:claim_aliases) { 'foo:bar, foo:baz, bing: blam'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00113E Failed to parse claim aliases: annotation name value 'foo' appears more than once"
        )
      end
    end
    context 'when claim alias target is defined multiple times' do
      let(:claim_aliases) { 'foo:bar, baz:bar, bing: blam'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00113E Failed to parse claim aliases: claim name value 'bar' appears more than once"
        )
      end
    end
    context 'when claim alias has more than one colon' do
      # TODO: This error message makes no sense
      let(:claim_aliases) { 'foo:bar:bling, baz:bang'}
      it 'is unsuccessful' do
        expect(subject.success?).to be(false)
        expect(subject.errors.first.text).to eq(
          "CONJ00114E Failed to parse claim aliases: the claim alias name 'foo:bar:bling' contains '/'."
        )
      end
    end
    context 'with claim alias in reserved claim list' do
      let(:contract) { Authentication::AuthnJwt::V2::DataObjects::AuthenticatorContract.new }
      %w[iss exp nbf iat jti aud].each do |reserved_claim|
        enforced_claims = "foo:bar/b, #{reserved_claim}:bing/baz"
        it 'is unsuccessful' do
          result = contract.call(**default_args.merge(claim_aliases: enforced_claims, jwks_uri: 'foo'))
          expect(result.success?).to be(false)
          expect(result.errors.first.text).to eq(
            "CONJ00105E Failed to validate claim: claim name '#{reserved_claim}' is in denylist '[\"iss\", \"exp\", \"nbf\", \"iat\", \"jti\", \"aud\"]'"
          )
        end
      end
    end
    context 'with claim target in reserved claim list' do
      let(:contract) { Authentication::AuthnJwt::V2::DataObjects::AuthenticatorContract.new }
      %w[iss exp nbf iat jti aud].each do |reserved_claim|
        enforced_claims = "foo:bar/b, bing:#{reserved_claim}"
        it 'is unsuccessful' do
          result = contract.call(**default_args.merge(claim_aliases: enforced_claims, jwks_uri: 'foo'))
          expect(result.success?).to be(false)
          expect(result.errors.first.text).to eq(
            "CONJ00105E Failed to validate claim: claim name '#{reserved_claim}' is in denylist '[\"iss\", \"exp\", \"nbf\", \"iat\", \"jti\", \"aud\"]'"
          )
        end
      end
    end
  end
end
