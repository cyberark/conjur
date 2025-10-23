require 'spec_helper'

describe Authenticators::Validator do
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

  let(:type) { "jwt" }
  let(:name) { "test" }
  let(:enabled) { true }
  let(:owner) { nil }
  let(:annotations) { nil }
  let(:data) { { jwks_uri: "https::jwks" } }

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

  describe "#call" do
    subject do
      Authenticators::Validator.new.call(authenticator_hash, account)
    end

    context "invalid values" do 
      context "when name is not valid" do
        context "invalid value type" do
          let(:name) { 123 }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'name' parameter must be of 'type=string'")
          end
        end

        context "missing name" do
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

        context "bad characters" do
          let(:name) { "asdf/" }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "Invalid 'name' parameter. Valid characters: letters, numbers, and these special characters are allowed: . _ : -. Other characters are not allowed."
            )
          end
        end

        context "empty name" do
          let(:name) { "" }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: name")
          end
        end
      end

      context "When enabled is not valid" do
        context "invalid value type" do
          let(:enabled) { "test" }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'enabled' parameter must be of 'type=true, false'")
          end
        end
      end

      context "when owner is invalid" do
        context "invalid value type" do
          let(:owner) { "test" }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'owner' parameter must be of 'type=object'")
          end
        end

        context "invalid id value type" do
          let(:owner) { { kind: "policy", id: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'id' parameter must be of 'type=string'")
          end
        end

        context "invalid kind value type" do
          let(:owner) { { kind: 123, id: "test" } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'kind' parameter must be of 'type=string'")
          end
        end

        context "missing id" do
          let(:owner) { { kind: "group" } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: id")
          end
        end

        context "missing kind" do
          let(:owner) { { id: "test" } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: kind")
          end
        end

        context "bad characters in id" do
          let(:owner) { { kind: "group", id: "test!123" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "Invalid 'id' parameter. Valid characters: letters, numbers, and these special characters are allowed: @ . _ / -. Other characters are not allowed."
            )
          end
        end

        context "invalid kind" do
          let(:owner) { { kind: "policy", id: "test" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterValueInvalid,
              "CONJ00191W The value in the Resource 'test' kind parameter is not valid. Error: Allowed values are [\"user\", \"host\", \"group\"]"
            )
          end
        end

        context "extra owner params" do
          let(:owner) { { kind: "group", id: "test", extra: "bad" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "The following parameters were not expected: extra"
            )
          end
        end
      end

      context "when annotations are not valid" do
        context "invalid value type" do
          let(:annotations) { "test" }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'annotations' parameter must be of 'type=object'")
          end
        end

        context "invalid annotation name character" do
          let(:annotations) { { "test@123": "value" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "Invalid 'annotation name' parameter. Valid characters: letters, numbers, and these special characters are allowed: _ / -. Other characters are not allowed."
            )
          end
        end

        context "invalid annotation value character" do
          let(:annotations) { { test: "value<" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "Invalid 'annotation value' parameter. All characters except less than (<), greater than (>), and single quote (') are allowed."
            )
          end
        end

        context "invalid annotations value type" do
          let(:annotations) { { test: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'annotation value' parameter must be of 'type=string'")
          end
        end

        context "missing annotation value" do
          let(:annotations) { { test: nil } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: annotation value")
          end
        end

        context "empty annotation value" do
          let(:annotations) { { test: "" } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterMissing, "CONJ00190W Missing required parameter: annotation value")
          end
        end
      end
    end

    context "when its a gcp authenticator" do
      let(:type) {"gcp"}
      let(:name) {'default'}
      let(:data) {nil}
      let(:authenticator_hash) do
        {
          type: type,
          name: name,
          enabled: enabled,
          owner: owner,
          data: data,
          annotations: annotations
        }
      end
      context "non-default name" do
        let(:name) { "other" }
        it "returns an error" do
          expect{subject}.to raise_error(
            Exceptions::RecordNotFound,
            "Webservice 'conjur/gcp/other' not found in account 'cucumber'"
          )
        end
      end
      context "when data is invalid" do
        # This functionality is exclusive to GCP
        let(:data) { { test: "value" } }

        it "returns an error" do
          expect{subject}.to raise_error(
            ApplicationController::UnprocessableEntity,
            "The 'data' object cannot be specified for gcp authenticators."
          )
        end
      end
    end

    context "when its a jwt authenticator" do
      let(:type) { "jwt" }
      let(:owner) { { kind: "user", id: "some-user" } }
      let(:annotations){ { description: "testing" } }
      let(:data) do
        {
          jwks_uri: "https://uri",
          ca_cert: "CERT_DATA",
          identity: {
            enforced_claims: %w[one two],
            claim_aliases: {
              a: "b"
            }
          },
          audience: "aud"
        }
      end

      context "bad ca_cert value type" do
        let(:data) { { ca_cert: 123 } }

        it "returns an error" do
          expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'ca_cert' parameter must be of 'type=string'")
        end
      end

      context "bad audience value type" do
        let(:data) { { audience: 123 } }

        it "returns an error" do
          expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'audience' parameter must be of 'type=string'")
        end
      end

      context "bad issuer value type" do
        let(:data) { { issuer: 123 } }

        it "returns an error" do
          expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'issuer' parameter must be of 'type=string'")
        end
      end

      context "with bad data section" do
        context "missing data" do
          let(:authenticator_hash) do
            {
              name: name,
              type: type,
              enabled: enabled,
              owner: owner,
              annotations: annotations
            }
          end
          it "returns an error" do
            puts authenticator_hash
            expect{subject}.to raise_error(ApplicationController::UnprocessableEntity, "The 'data' object must be specified for jwt authenticators and it must be a non-empty JSON object.")
          end
        end

        context "empty data" do
          let(:data) { {} }
          it "returns an error" do
            expect{subject}.to raise_error(ApplicationController::UnprocessableEntity, "The 'data' object must be specified for jwt authenticators and it must be a non-empty JSON object.")
          end
        end

        context "extra data value" do
          let(:data) { { jwks_uri: "https::jwks", extra: "test" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "The following parameters were not expected: extra"
            )
          end
        end
      end

      context "when there is a issuer with jwks or public keys" do
        context "missing jwks_uri and public_keys" do
          let(:data) { { audience: "aud" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "In the 'data' object, either a 'jwks_uri' or 'public_keys' field must be specified."
            )
          end
        end

        context "both jwks_uri and public_keys" do
          let(:data) { { jwks_uri: "https://", public_keys: { test: "test" } } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "In the 'data' object, you cannot specify jwks_uri and public_keys fields."
            )
          end
        end

        context "public_keys with no issuer" do
          let(:data) { { public_keys: { test: "test" } } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "In the 'data' object, when the 'public_keys' field is specified, the 'issuer' field must also be specified."
            )
          end
        end

        context "bad jwks_uri value type" do
          let(:data) { { jwks_uri: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'jwks_uri' parameter must be of 'type=string'")
          end
        end

        context "bad public_keys value type" do
          let(:data) { { public_keys: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'public_keys' parameter must be of 'type=object'")
          end
        end
      end

      context "when identity data is not valid" do
        let(:data) { { jwks_uri: "https://uri", identity: identity } }

        context "identity_path with no token_app_property" do
          let(:identity) { { identity_path: "path" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "In the identity object, when the 'identity_path' field is specified, the 'token_app_property' field must also be specified."
            )
          end
        end

        context "claim aliases invalid value type" do
          let(:identity) { { claim_aliases: "bad" } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'claim_aliases' parameter must be of 'type=object'")
          end
        end

        context "using reserved claim aliases" do
          context "iss" do
            let(:identity) { { claim_aliases: { iss: "iss" } } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid target alias 'iss' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
              )
            end
          end

          context "exp" do
            let(:identity) { { claim_aliases: { exp: "exp" } } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid target alias 'exp' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
              )
            end
          end

          context "nbf" do
            let(:identity) { { claim_aliases: { nbf: "nbf" } } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid target alias 'nbf' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
              )
            end
          end

          context "iat" do
            let(:identity) { { claim_aliases: { iat: "iat" } } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid target alias 'iat' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
              )
            end
          end

          context "aud" do
            let(:identity) { { claim_aliases: { aud: "aud" } } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid target alias 'aud' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
              )
            end
          end

          context "jti" do
            let(:identity) { { claim_aliases: { jti: "jti" } } }

            it "returns an error" do
              expect{subject}.to raise_error(
                ApplicationController::UnprocessableEntity,
                "Invalid target alias 'jti' in 'claim_aliases'. Cannot use reserved claims: iss, exp, nbf, iat, aud, jti."
              )
            end
          end
        end

        context "bad claim alias character" do
          let(:identity) { { claim_aliases: { "test!": "iss" } } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "Invalid target alias 'test!' in 'claim_aliases'. Must be an alphanumeric string with underscores or dashes."
            )
          end
        end

        context "bad claim alias value character" do
          let(:identity) { { claim_aliases: { "test": "test\\ing" } } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "Invalid source claim 'test\\ing' in 'claim_aliases'. Must be a valid claim name or a nested path."
            )
          end
        end

        context "enforced claims invalid value type" do
          let(:identity) { { enforced_claims: "bad" } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'enforced_claims' parameter must be of 'type=array'")
          end
        end

        context "enforced claims invalid array value type" do
          let(:identity) { { enforced_claims: [ 123 ] } }

          it "returns an error" do
            expect{subject}.to raise_error(ApplicationController::UnprocessableEntity, "Invalid 'enforced_claims' parameter. Must be an array of strings.")
          end
        end

        context "identity path invalid value type" do
          let(:identity) { { identity_path: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'identity_path' parameter must be of 'type=string'")
          end
        end

        context "token app property invalid value type" do
          let(:identity) { { token_app_property: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'token_app_property' parameter must be of 'type=string'")
          end
        end
      end
    end

    context "ldap authenticator" do
      let(:type) { "ldap" }
      let(:data) { nil }

      context "with standard data values specified" do
        let(:annotations){ { description: "testing" } }
        let(:owner) { { kind: "user", id: "some-user" } }

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        context "with bind_password and tls_ca_cert specified" do
          let(:data) { { bind_password: "password", tls_ca_cert: "cert_data" } }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end
        end

        context "with bind_password specified" do
          let(:data) { { bind_password: "password" } }

          it "does not raise an error" do
            expect { subject }.not_to raise_error
          end
        end
      end

      context "with data section specified" do
        context "With extra data key" do
          let(:data) { { some: "data" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              ApplicationController::UnprocessableEntity,
              "The following parameters were not expected: some"
            )
          end
        end

        context "with tls_ca_cert specified but missing bind_password" do
          let(:data) { { tls_ca_cert: "cert_data" } }

          it "returns an error" do
            expect { subject }.to raise_error(
              Errors::Conjur::ParameterMissing,
              "CONJ00190W Missing required parameter: The 'bind_password' field must be specified when the 'tls_ca_cert' field is provided."
            )
          end
        end
      end
    end

    context "AWS Authenticator" do
      let(:type) { "aws" }
      let(:data) { nil }

      context "with standard data values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end
      end

      context "with extra data key" do
        let(:data) { { some: "data" } }

        it "returns an error" do
          expect{subject}.to raise_error(
            ApplicationController::UnprocessableEntity,
            "The 'data' object cannot be specified for aws authenticators."
          )
        end
      end
    end

    context "oidc authenticator" do
      let(:type) { "oidc" }

      context "with standard data values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            provider_uri: "https://uri",
            id_token_user_property: "prop"
          }
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end
      end

      context "with mfa data values specified" do
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

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end
      end

      context "with bad data section" do
        context "bad provider_uri value type" do
          let(:data) { { provider_uri: 123, id_token_user_property: "prop" } }

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'provider_uri' parameter must be of 'type=string'"
            )
          end
        end

        context "bad id_token_user_property value type" do
          let(:data) { { provider_uri: "123", id_token_user_property: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(
              Errors::Conjur::ParameterTypeInvalid,
              "CONJ00192W The 'id_token_user_property' parameter must be of 'type=string'"
            )
          end
        end

        context "bad client_id value type" do
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

        context "bad client_secret value type" do
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

        context "bad redirect_uri value type" do
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

        context "bad claim_mapping value type" do
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

        context "bad name value type" do
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

        context "bad ca_cert value type" do
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

        context "bad token_ttl value type" do
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

        context "bad provider_scope value type" do
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

        context "partial configuration for both ODIC types" do
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

        context "full configuration for both ODIC types" do
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

    context "azure authenticator" do
      let(:type) { "azure" }

      context "with values specified" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            provider_uri: "https://uri"
          }
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end
      end

      context "with bad data section" do
        context "bad provider_uri value type" do
          let(:data) { { provider_uri: 123 } }

          it "returns an error" do
            expect{subject}.to raise_error(Errors::Conjur::ParameterTypeInvalid, "CONJ00192W The 'provider_uri' parameter must be of 'type=string'")
          end
        end
      end
    end

    context "k8s authenticator" do
      let(:type) { "k8s" }

      context "with values specified" do
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

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end
      end

      context "with kubernetes/* values missing" do
        let(:owner) { { kind: "user", id: "some-user" } }
        let(:annotations){ { description: "testing" } }
        let(:data) do
          {
            "ca/cert": "ca-cert",
            "ca/key": "ca-key"
          }
        end

        context "missing ca/cert" do
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

        context "missing ca/key" do
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

        context "bad value type for kubernetes/ca_cert" do
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

        context "bad value type for kubernetes/service_account_token" do
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

        context "bad value type for kubernetes/api_url" do
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

        context "bad value type for ca/cert" do
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

        context "bad value type for ca/key" do
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
  end
end
