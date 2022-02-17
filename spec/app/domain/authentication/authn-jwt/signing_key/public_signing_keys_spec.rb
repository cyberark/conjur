# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::SigningKey::PublicSigningKeys') do

  invalid_cases = {
    "When public-keys value is a string":
      ["blah",
       "Value not in valid JSON format"],
    "When public-keys value is an array":
      [%w[a b],
       "Value not in valid JSON format"],
    "When public-keys value is an empty object":
      [{},
       "Type can't be blank, Value can't be blank, and Type '' is not a valid public-keys type. Valid types are: jwks"],
    "When public-keys does not contain needed fields":
      [{:key => "value", :key2 => { :key3 => "valve" }},
       "Type can't be blank, Value can't be blank, and Type '' is not a valid public-keys type. Valid types are: jwks"],
    "When public-keys type is empty and value is absent":
      [{:type => ""},
       "Type can't be blank, Value can't be blank, and Type '' is not a valid public-keys type. Valid types are: jwks"],
    "When public-keys type has wrong value and value is absent":
      [{:type => "yes"},
       "Value can't be blank and Type 'yes' is not a valid public-keys type. Valid types are: jwks"],
    "When public-keys type is valid and value is a string":
      [{:type => "jwks", :value => "string"},
       "Value is not a valid JWKS (RFC7517)"],
    "When public-keys type is valid and value is an empty object":
      [{:type => "jwks", :value => { } },
       "Value can't be blank and Value is not a valid JWKS (RFC7517)"],
    "When public-keys type is valid and value is an object with some key":
      [{:type => "jwks", :value => { :some_key => "some_value" } },
       "Value is not a valid JWKS (RFC7517)"],
    "When public-keys type is valid and value is an object with `keys` key and string keys value":
      [{:type => "jwks", :value => { :keys => "some_value" } },
       "Value is not a valid JWKS (RFC7517)"],
    "When public-keys type is valid and value is an object with `keys` key and empty array keys value":
      [{:type => "jwks", :value => { :keys => [ ] } },
       "Value is not a valid JWKS (RFC7517)"],
    "When public-keys type is invalid and value is an object with `keys` key and none empty array keys value":
      [{:type => "invalid", :value => { :keys => [ "some_value" ] } },
       "Type 'invalid' is not a valid public-keys type. Valid types are: jwks"]
  }

  let(:valid_jwks) {
    {:type => "jwks", :value => { :keys => [ "some_value" ] } }
  }

  context "Public-keys value validation" do
    context "Invalid examples" do
      invalid_cases.each do |description, (hash, expected_error_message) |
        context "#{description}" do
          subject do
            Authentication::AuthnJwt::SigningKey::PublicSigningKeys.new(hash)
          end

          it "raises an error" do

            expect { subject.validate! }
              .to raise_error(
                    Errors::Authentication::AuthnJwt::InvalidPublicKeys,
                    "CONJ00120E Failed to parse 'public-keys': #{expected_error_message}")
          end
        end
      end
    end

    context "Valid examples" do
      context "When public-keys type is jwks and value meets minimal jwks requirements" do
        subject do
          Authentication::AuthnJwt::SigningKey::PublicSigningKeys.new(valid_jwks)
        end

        it "validates! does not raise error" do
          expect { subject.validate! }
            .not_to raise_error
        end

        it "type is jwks" do
          expect(subject.type).to eql("jwks")
        end

        it "can create JWKS from value" do
          expect { JSON::JWK::Set.new(subject.value) }
            .not_to raise_error
        end
      end
    end
  end
end
