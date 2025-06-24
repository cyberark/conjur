require 'spec_helper'

describe AuthenticatorsV2::AuthenticatorTypeFactory do
  describe "#create_authenticator_type" do
    let(:factory) { described_class.new }
    let(:type) { "jwt" }
    let(:authenticator_dict) do
      OpenStruct.new(
        type: "authn-#{type}",
        service_id: "auth1",
        enabled: true,
        owner_id: "rspec:policy:conjur/base",
        annotations: `{ "name": "description", "value": "this is my #{type} authenticator" }`,
        variables: {
          "rspec:variable:conjur/authn-#{type}/auth1/ca-cert" => "CERT_DATA_1"
        }
      )
    end

    context "when type is 'jwt'" do
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::JwtAuthenticatorType) }

      it "creates a JWT authenticator successfully" do
        expect(AuthenticatorsV2::JwtAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'aws'" do
      let(:type) { "iam" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::AwsAuthenticatorType) }

      it "creates a AWS authenticator successfully" do
        expect(AuthenticatorsV2::AwsAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'azure'" do
      let(:type) { "azure" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::AzureAuthenticatorType) }

      it "creates a Azure authenticator successfully" do
        expect(AuthenticatorsV2::AzureAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'gcp'" do
      let(:type) { "gcp" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::GcpAuthenticatorType) }

      it "creates a Gcp authenticator successfully" do
        expect(AuthenticatorsV2::GcpAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'k8s'" do
      let(:type) { "k8s" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::K8sAuthenticatorType) }

      it "creates a K8s authenticator successfully" do
        expect(AuthenticatorsV2::K8sAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is 'ldap'" do
      let(:type) { "ldap" }
      let(:authenticator_instance) { instance_double(AuthenticatorsV2::LdapAuthenticatorType) }

      it "creates a ldap authenticator successfully" do
        expect(AuthenticatorsV2::LdapAuthenticatorType).to receive(:new).with(authenticator_dict).and_return(authenticator_instance)
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.result).to be(authenticator_instance)
      end
    end

    context "when type is unsupported" do
      let(:type) { "test" }
      it "raises an error for an unsupported type" do
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.success?).to be(false)
        expect(authenticator.exception).to be(ApplicationController::UnprocessableEntity)
        expect(authenticator.status).to eq(:unprocessable_entity)
      end
    end

    context "when type is nil" do
      let(:authenticator_dict) do
        {
          service_id: "auth1",
          enabled: true,
          owner_id: "rspec:policy:conjur/base",
          variables: ""
        }
      end

      it "raises an error for missing authenticator type" do
        authenticator = factory.create_authenticator_type(authenticator_dict)
        expect(authenticator.success?).to be(false)
        expect(authenticator.exception).to be(ApplicationController::UnprocessableEntity)
        expect(authenticator.status).to eq(:unprocessable_entity)
      end
    end
  end

  describe "#create_authenticator_from_json" do
    subject do
      AuthenticatorsV2::AuthenticatorTypeFactory.new.create_authenticator_from_json(authenticator_json, account)
    end

    let(:authenticator_json) do
      JSON.dump(authenticator_hash.compact)
    end
    let(:account) { "cucumber" }
    let(:branch) do
      if type == "aws"
        "conjur/authn-iam"
      else
        "conjur/authn-#{type}"
      end
    end
    let(:default_owner) do
      {
        kind: "policy",
        id: branch
      }
    end

    let(:type) { nil }
    let(:name) { "test" }
    let(:enabled) { true }
    let(:owner) { nil }
    let(:annotations) { nil }
    let(:data) { nil }

    let(:authenticator_hash) do
      {
        type: type,
        name: name,
        enabled: enabled,
        owner: owner,
        annotations: annotations,
        data: data
      }
    end

    describe "gcp authenticator" do
      let(:type) { "gcp" }
      let(:name) { "default" }

      describe "with no owner" do
        it "Returns the default owner" do

          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: default_owner
          })
        end
      end

      describe "with owner" do
        let(:owner){ { kind: "user", id: "alice" } }

        it "returns the same owner" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: owner
          })
        end
      end

      describe "with annotations" do
        let(:annotations){ { description: "testing" } }

        it "returns the same annotations" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: default_owner,
            annotations: annotations
          })
        end
      end

      describe "invalid values" do
        # Describes all error scenarios common to all authenticators when creating from JSON

        describe "type" do
          describe "missing auth type" do
            let(:authenticator_hash) do
              {
                name: name,
                enabled: enabled,
                owner: owner,
                annotations: annotations,
                data: data
              }
            end

            it "returns an error" do
              expect(subject.message).to eq("Authenticator type is required")
            end
          end

          describe "invalid auth type" do
            let(:type) { "bad" }

            it "returns an error" do
              expect(subject.message).to eq("'authn-bad' authenticators are not supported.")
            end
          end

          describe "invalid value type for type" do
            let(:type) { 123 }

            it "returns an error" do
              expect(subject.message).to eq("'authn-123' authenticators are not supported.")
            end
          end
        end

        describe "name" do
          describe "invalid value type" do
            let(:name) { 123 }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'name' parameter must be of 'type=string'")
            end
          end

          describe "missing name" do
            let(:authenticator_hash) do
              {
                type: type,
                enabled: enabled,
                owner: owner,
                annotations: annotations,
                data: data
              }
            end

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: name")
            end
          end

          describe "bad characters" do
            let(:name) { "asdf/" }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid 'name' parameter. Valid characters: letters, numbers, and these special characters are allowed: . _ : -. Other characters are not allowed."
              )
            end
          end

          describe "empty name" do
            let(:name) { "" }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: name")
            end
          end

          describe "non-default name" do
            let(:name) { "other" }

            it "returns an error" do
              expect{subject}.to raise_error(
                Exceptions::RecordNotFound,
                "Webservice 'conjur/gcp/other' not found in account 'cucumber'"
              )
            end
          end
        end

        describe "enabled" do
          describe "invalid value type" do
            let(:enabled) { "test" }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'enabled' parameter must be of 'type=true, false'")
            end
          end
        end

        describe "owner" do
          describe "invalid value type" do
            let(:owner) { "test" }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'owner' parameter must be of 'type=object'")
            end
          end

          describe "invalid id value type" do
            let(:owner) { { kind: "policy", id: 123 } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'id' parameter must be of 'type=string'")
            end
          end

          describe "invalid kind value type" do
            let(:owner) { { kind: 123, id: "test" } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'kind' parameter must be of 'type=string'")
            end
          end

          describe "missing id" do
            let(:owner) { { kind: "group" } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: id")
            end
          end

          describe "missing kind" do
            let(:owner) { { id: "test" } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: kind")
            end
          end

          describe "bad characters in id" do
            let(:owner) { { kind: "group", id: "test!123" } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid 'id' parameter. Valid characters: letters, numbers, and these special characters are allowed: @ . _ / -. Other characters are not allowed."
              )
            end
          end

          describe "invalid kind" do
            let(:owner) { { kind: "policy", id: "test" } }

            it "returns an error" do
              expect{subject}.to raise_error(
                Errors::Conjur::ParameterValueInvalid,
                "CONJ00191W The value in the Resource 'test' kind parameter is not valid. Error: Allowed values are [\"user\", \"host\", \"group\"]"
              )
            end
          end

          describe "extra owner params" do
            let(:owner) { { kind: "group", id: "test", extra: "bad" } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "The following parameters were not expected: extra"
              )
            end
          end
        end

        describe "data" do
          # This functionality is exclusive to GCP
          let(:data) { { test: "value" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "The 'data' object cannot be specified for gcp authenticators."
            )
          end
        end

        describe "annotations" do
          describe "invalid value type" do
            let(:annotations) { "test" }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'annotations' parameter must be of 'type=object'")
            end
          end

          describe "invalid annotation name character" do
            let(:annotations) { { "test@123": "value" } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid 'annotation name' parameter. Valid characters: letters, numbers, and these special characters are allowed: _ / -. Other characters are not allowed."
              )
            end
          end

          describe "invalid annotation value character" do
            let(:annotations) { { test: "value<" } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid 'annotation value' parameter. All characters except less than (<), greater than (>), and single quote (') are allowed."
              )
            end
          end

          describe "invalid annotations value type" do
            let(:annotations) { { test: 123 } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'annotation value' parameter must be of 'type=string'")
            end
          end

          describe "missing annotation value" do
            let(:annotations) { { test: nil } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: annotation value")
            end
          end

          describe "empty annotation value" do
            let(:annotations) { { test: "" } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: annotation value")
            end
          end
        end
      end
    end

    describe "jwt authenticator" do
      let(:type) { "jwt" }

      describe "with values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            jwks_uri: "https://uri",
            ca_cert: "CERT_DATA",
            identity: {
              enforced_claims: [ "one", "two" ],
              claim_aliases: {
                a: "b"
              }
            },
            audience: "aud"
          }
        end

        it "returns the authenticator" do
            expect(subject.result.to_h).to eq({
              type: type,
              branch: branch,
              name: name,
              enabled: enabled,
              owner: owner,
              annotations: annotations,
              data: data
            })
        end
      end

      describe "with bad data section" do
        describe "missing data" do
          it "returns an error" do
            expect{subject}.to raise_error(ApplicationController::UnprocessableEntity, "The 'data' object must be specified for jwt authenticators and it must be a non-empty JSON object.")
          end
        end

        describe "empty data" do
          let(:data) { {} }
          it "returns an error" do
            expect{subject}.to raise_error(ApplicationController::UnprocessableEntity, "The 'data' object must be specified for jwt authenticators and it must be a non-empty JSON object.")
          end
        end

        describe "extra data value" do
          let(:data) { { jwks_uri: "https::jwks", extra: "test" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "The following parameters were not expected: extra"
            )
          end
        end

        describe "missing jwks_uri and public_keys" do
          let(:data) { { audience: "aud" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "In the 'data' object, either a 'jwks_uri' or 'public_keys' field must be specified."
            )
          end
        end

        describe "both jwks_uri and public_keys" do
          let(:data) { { jwks_uri: "https://", public_keys: "keys" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "In the 'data' object, you cannot specify jwks_uri and public_keys fields."
            )
          end
        end

        describe "public_keys with no issuer" do
          let(:data) { { public_keys: "keys" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "In the 'data' object, when the 'public_keys' field is specified, the 'issuer' field must also be specified."
            )
          end
        end

        describe "bad jwks_uri value type" do
          let(:data) { { jwks_uri: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'jwks_uri' parameter must be of 'type=string'")
          end
        end

        describe "bad public_keys value type" do
          let(:data) { { public_keys: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'public_keys' parameter must be of 'type=string'")
          end
        end

        describe "bad ca_cert value type" do
          let(:data) { { ca_cert: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'ca_cert' parameter must be of 'type=string'")
          end
        end

        describe "bad audience value type" do
          let(:data) { { audience: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'audience' parameter must be of 'type=string'")
          end
        end

        describe "bad issuer value type" do
          let(:data) { { issuer: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'issuer' parameter must be of 'type=string'")
          end
        end

        describe "identity data" do
          let(:data) { { jwks_uri: "https://uri", identity: identity } }

          describe "identity_path with no token_app_property" do
            let(:identity) { { identity_path: "path" } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "In the identity object, when the 'identity_path' field is specified, the 'token_app_property' field must also be specified."
              )
            end
          end

          describe "claim aliases invalid value type" do
            let(:identity) { { claim_aliases: "bad" } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'claim_aliases' parameter must be of 'type=object'")
            end
          end

          describe "using reserved claim aliases" do
            describe "iss" do
              let(:identity) { { claim_aliases: { iss: "iss" } } }

              it "returns an error" do
                expect{subject}.to raise_error(
                  ApplicationController::UnprocessableEntity,
                  "Invalid target alias 'iss' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
                )
              end
            end

            describe "exp" do
              let(:identity) { { claim_aliases: { exp: "exp" } } }

              it "returns an error" do
                expect{subject}.to raise_error(
                  ApplicationController::UnprocessableEntity,
                  "Invalid target alias 'exp' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
                )
              end
            end

            describe "nbf" do
              let(:identity) { { claim_aliases: { nbf: "nbf" } } }

              it "returns an error" do
                expect{subject}.to raise_error(
                  ApplicationController::UnprocessableEntity,
                  "Invalid target alias 'nbf' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
                )
              end
            end

            describe "iat" do
              let(:identity) { { claim_aliases: { iat: "iat" } } }

              it "returns an error" do
                expect{subject}.to raise_error(
                  ApplicationController::UnprocessableEntity,
                  "Invalid target alias 'iat' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
                )
              end
            end

            describe "aud" do
              let(:identity) { { claim_aliases: { aud: "aud" } } }

              it "returns an error" do
                expect{subject}.to raise_error(
                  ApplicationController::UnprocessableEntity,
                  "Invalid target alias 'aud' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
                )
              end
            end

            describe "jti" do
              let(:identity) { { claim_aliases: { jti: "jti" } } }

              it "returns an error" do
                expect{subject}.to raise_error(
                  ApplicationController::UnprocessableEntity,
                  "Invalid target alias 'jti' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
                )
              end
            end
          end

          describe "bad claim alias character" do
            let(:identity) { { claim_aliases: { "test!": "iss" } } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid target alias 'test!' in 'claim_aliases'. Must be an alphanumeric string with underscores or dashes."
              )
            end
          end

          describe "bad claim alias value character" do
            let(:identity) { { claim_aliases: { "test": "test\\ing" } } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid source claim 'test\\ing' in 'claim_aliases'. Must be a valid claim name or a nested path."
              )
            end
          end

          describe "enforced claims invalid value type" do
            let(:identity) { { enforced_claims: "bad" } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'enforced_claims' parameter must be of 'type=array'")
            end
          end

          describe "enforced claims invalid array value type" do
            let(:identity) { { enforced_claims: [ 123 ] } }

            it "returns an error" do
              expect{subject}.to raise_error(ApplicationController::UnprocessableEntity, "Invalid 'enforced_claims' parameter. Must be an array of strings.")
            end
          end

          describe "identity path invalid value type" do
            let(:identity) { { identity_path: 123 } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'identity_path' parameter must be of 'type=string'")
            end
          end

          describe "token app property invalid value type" do
            let(:identity) { { token_app_property: 123 } }

            it "returns an error" do
              expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'token_app_property' parameter must be of 'type=string'")
            end
          end
        end
      end
    end

    describe "k8s authenticator" do
      let(:type) { "k8s" }

      describe "with values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            "kubernetes/ca_cert": "cert",
            "kubernetes/service_account_token": "token",
            "kubernetes/api_url": "https://api",
            "ca/cert": "ca-cert",
            "ca/key": "ca-key"
          }
        end

        it "returns the authenticator" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: owner,
            annotations: annotations,
            data: data
          })
        end
      end

      describe "with kubernetes/* values missing" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            "ca/cert": "ca-cert",
            "ca/key": "ca-key"
          }
        end

        it "returns the authenticator" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: owner,
            annotations: annotations,
            data: data
          })
        end
      end

      describe "with bad data section" do
        describe "missing ca/cert" do
          let(:data) do
            {
              "kubernetes/ca_cert": "token",
              "kubernetes/service_account_token": "https://api",
              "kubernetes/api_url": "ca-cert",
              "ca/key": "ca-key"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: ca/cert")
          end
        end

        describe "missing ca/key" do
          let(:data) do
            {
              "kubernetes/ca_cert": "token",
              "kubernetes/service_account_token": "https://api",
              "kubernetes/api_url": "ca-cert",
              "ca/cert": "ca-key"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: ca/key")
          end
        end

        describe "bad value type for kubernetes/ca_cert" do
          let(:data) do
            {
              "kubernetes/ca_cert": 123,
              "kubernetes/service_account_token": "token",
              "kubernetes/api_url": "https://api",
              "ca/cert": "ca-cert",
              "ca/key": "ca-key"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'kubernetes/ca_cert' parameter must be of 'type=string'")
          end
        end

        describe "bad value type for kubernetes/service_account_token" do
          let(:data) do
            {
              "kubernetes/ca_cert": "cert",
              "kubernetes/service_account_token": 123,
              "kubernetes/api_url": "https://api",
              "ca/cert": "ca-cert",
              "ca/key": "ca-key"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'kubernetes/service_account_token' parameter must be of 'type=string'")
          end
        end

        describe "bad value type for kubernetes/api_url" do
          let(:data) do
            {
              "kubernetes/ca_cert": "123",
              "kubernetes/service_account_token": "token",
              "kubernetes/api_url": 123,
              "ca/cert": "ca-cert",
              "ca/key": "ca-key"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'kubernetes/api_url' parameter must be of 'type=string'")
          end
        end

        describe "bad value type for ca/cert" do
          let(:data) do
            {
              "kubernetes/ca_cert": "123",
              "kubernetes/service_account_token": "token",
              "kubernetes/api_url": "https://api",
              "ca/cert": 123,
              "ca/key": "ca-key"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'ca/cert' parameter must be of 'type=string'")
          end
        end

        describe "bad value type for ca/key" do
          let(:data) do
            {
              "kubernetes/ca_cert": "123",
              "kubernetes/service_account_token": "token",
              "kubernetes/api_url": "https://api",
              "ca/cert": "ca-cert",
              "ca/key": 123
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'ca/key' parameter must be of 'type=string'")
          end
        end
      end
    end

    describe "azure authenticator" do
      let(:type) { "azure" }

      describe "with values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            provider_uri: "https://uri"
          }
        end

        it "returns the authenticator" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: owner,
            annotations: annotations,
            data: data
          })
        end
      end

      describe "with bad data section" do
        describe "bad provider_uri value type" do
          let(:data) { { provider_uri: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'provider_uri' parameter must be of 'type=string'")
          end
        end
      end
    end

    describe "oidc authenticator" do
      let(:type) { "oidc" }

      describe "with standard data values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            provider_uri: "https://uri",
            id_token_user_property: "prop"
          }
        end

        it "returns the authenticator" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: owner,
            annotations: annotations,
            data: data
          })
        end
      end

      describe "with mfa data values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            provider_uri: "https://uri",
            client_id: "test",
            client_secret: "secret",
            redirect_uri: "https://uri",
            claim_mapping: "map"
          }
        end

        it "returns the authenticator" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: owner,
            annotations: annotations,
            data: data
          })
        end
      end

      describe "with bad data section" do
        describe "bad provider_uri value type" do
          let(:data) { { provider_uri: 123, id_token_user_property: "prop" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'provider_uri' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad id_token_user_property value type" do
          let(:data) { { provider_uri: "123", id_token_user_property: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'id_token_user_property' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad client_id value type" do
          let(:data) do
            {
              provider_uri: "123",
              client_id: 123,
              client_secret: "secret",
              redirect_uri: "https://uri",
              claim_mapping: "map"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'client_id' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad client_secret value type" do
          let(:data) do
            {
              provider_uri: "123",
              client_id: "id",
              client_secret: 123,
              redirect_uri: "https://uri",
              claim_mapping: "map"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'client_secret' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad redirect_uri value type" do
          let(:data) do
            {
              provider_uri: "123",
              client_id: "id",
              client_secret: "123",
              redirect_uri: 123,
              claim_mapping: "map"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'redirect_uri' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad claim_mapping value type" do
          let(:data) do
            {
              provider_uri: "123",
              client_id: "id",
              client_secret: "123",
              redirect_uri: "123",
              claim_mapping: 123
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'claim_mapping' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad name value type" do
          let(:data) do
            {
              provider_uri: "123",
              client_id: "id",
              client_secret: "123",
              redirect_uri: "123",
              claim_mapping: "123",
              name: 123
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'name' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad ca_cert value type" do
          let(:data) do
            {
              provider_uri: "123",
              client_id: "id",
              client_secret: "123",
              redirect_uri: "123",
              claim_mapping: "123",
              ca_cert: 123
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'ca_cert' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad token_ttl value type" do
          let(:data) do
            {
              provider_uri: "123",
              client_id: "id",
              client_secret: "123",
              redirect_uri: "123",
              claim_mapping: "123",
              token_ttl: 123
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'token_ttl' parameter must be of 'type=string'"
            )
          end
        end

        describe "bad provider_scope value type" do
          let(:data) do
            {
              provider_uri: "123",
              client_id: "id",
              client_secret: "123",
              redirect_uri: "123",
              claim_mapping: "123",
              provider_scope: 123
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'provider_scope' parameter must be of 'type=string'"
            )
          end
        end

        describe "partial configuration for both ODIC types" do
          let(:data) do
            {
              provider_uri: "http://test",
              id_token_user_property: "prop",
              client_id: "test"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "The data object must contain either [\"id_token_user_property\"] or [\"client_id\", \"client_secret\", \"redirect_uri\", \"claim_mapping\"] keys."
            )
          end
        end

        describe "full configuration for both ODIC types" do
          let(:data) do
            {
              provider_uri: "http://test",
              id_token_user_property: "prop",
              client_id: "test",
              client_secret: "secret",
              redirect_uri: "https://uri",
              claim_mapping: "map"
            }
          end

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "The data object must contain either [\"id_token_user_property\"] or [\"client_id\", \"client_secret\", \"redirect_uri\", \"claim_mapping\"] keys."
            )
          end
        end
      end
    end

    describe "ldap authenticator" do
      let(:type) { "ldap" }

      describe "with standard data values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }

        it "returns the authenticator" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: owner,
            annotations: annotations
          })
        end
      end

      describe "with data section specified" do
        let(:data) { {some: "data" } }

        it "returns an error" do
          expect{subject}.to raise_error(
            ApplicationController::UnprocessableEntity,
            "The 'data' object cannot be specified for ldap authenticators."
          )
        end
      end
    end

    describe "aws authenticator" do
      let(:type) { "aws" }

      describe "with standard data values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }

        it "returns the authenticator" do
          expect(subject.result.to_h).to eq({
            type: type,
            branch: branch,
            name: name,
            enabled: enabled,
            owner: owner,
            annotations: annotations
          })
        end
      end

      describe "with data section specified" do
        let(:data) { {some: "data" } }

        it "returns an error" do
          expect{subject}.to raise_error(
            ApplicationController::UnprocessableEntity,
            "The 'data' object cannot be specified for aws authenticators."
          )
        end
      end
    end
  end
end
