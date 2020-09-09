# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication::AuthnGcp::DecodedToken' do

  let(:sub_value) { "some_sub_value" }
  let(:aud_value) { "some_aud_value" }
  let(:email_value) { "some_email_value" }
  let(:instance_name_value) { "some_instance_name_value" }
  let(:project_id_value) { "some_project_id_value" }

  def decoded_token_hash(token_str)
    JSON.parse(token_str.gsub("\n", '')).to_hash
  end

  let(:decoded_token_hash_valid) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "sub": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}", 
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_missing_aud) do
    decoded_token_hash(
      <<~EOS
        {
          "sub": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}", 
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_empty_aud) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "", 
          "sub": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}", 
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_missing_sub) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}", 
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_empty_sub) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}", 
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_missing_email) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "sub": "#{sub_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}", 
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_empty_email) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "sub": "#{sub_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}", 
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_missing_instance_name) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "sub": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_empty_instance_name) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "sub": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "project_id": "#{project_id_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_missing_project_id) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "sub": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}"
            }
          }
        }
    EOS
    )
  end

  let(:decoded_token_hash_empty_project_id) do
    decoded_token_hash(
      <<~EOS
        {
          "aud": "#{sub_value}", 
          "sub": "#{sub_value}", 
          "email": "#{email_value}", 
          "google": {
            "compute_engine": {
              "instance_name": "#{instance_name_value}"
            }
          }
        }
    EOS
    )
  end

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "A decoded token" do
    context "that has all required token claims" do
      subject(:decoded_token) do
        ::Authentication::AuthnGcp::DecodedToken.new(
          decoded_token_hash: decoded_token_hash_valid,
          logger:             Rails.logger
        )
      end

      it "does not raise an error" do
        expect { decoded_token }.to_not raise_error
      end

      it "parses the token expectedly" do
        expect(decoded_token.project_id).to eq(project_id_value)
        expect(decoded_token.instance_name).to eq(instance_name_value)
        expect(decoded_token.service_account_id).to eq(sub_value)
        expect(decoded_token.service_account_email).to eq(email_value)
      end
    end

    context "that is missing required token claims" do
      context "missing aud claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_missing_aud,
            logger:             Rails.logger
          )
        end

        it "raises an error" do
          expect { decoded_token }.to raise_error(Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty)
        end
      end

      context "empty aud claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_empty_aud,
            logger:             Rails.logger
          )
        end

        it "raises an error" do
          expect { decoded_token }.to raise_error(Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty)
        end
      end

      context "missing sub claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_missing_sub,
            logger:             Rails.logger
          )
        end

        it "raises an error" do
          expect { decoded_token }.to raise_error(Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty)
        end
      end

      context "empty sub claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_empty_sub,
            logger:             Rails.logger
          )
        end

        it "raises an error" do
          expect { decoded_token }.to raise_error(Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty)
        end
      end

      context "missing email claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_missing_email,
            logger:             Rails.logger
          )
        end

        it "raises an error" do
          expect { decoded_token }.to raise_error(Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty)
        end
      end

      context "empty email claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_empty_email,
            logger:             Rails.logger
          )
        end

        it "raises an error" do
          expect { decoded_token }.to raise_error(Errors::Authentication::Jwt::TokenClaimNotFoundOrEmpty)
        end
      end
    end

    context "that is missing optional token claims" do
      context "missing instance_name claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_missing_instance_name,
            logger:             Rails.logger
          )
        end

        it "does not raise an error" do
          expect { decoded_token }.to_not raise_error
        end

        it "parses the token expectedly" do
          expect(decoded_token.project_id).to eq(project_id_value)
          expect(decoded_token.instance_name).to eq(nil)
          expect(decoded_token.service_account_id).to eq(sub_value)
          expect(decoded_token.service_account_email).to eq(email_value)
        end
      end

      context "empty instance_name claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_empty_instance_name,
            logger:             Rails.logger
          )
        end

        it "does not raise an error" do
          expect { decoded_token }.to_not raise_error
        end

        it "parses the token expectedly" do
          expect(decoded_token.project_id).to eq(project_id_value)
          expect(decoded_token.instance_name).to eq(nil)
          expect(decoded_token.service_account_id).to eq(sub_value)
          expect(decoded_token.service_account_email).to eq(email_value)
        end
      end

      context "missing project_id claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_missing_project_id,
            logger:             Rails.logger
          )
        end

        it "does not raise an error" do
          expect { decoded_token }.to_not raise_error
        end

        it "parses the token expectedly" do
          expect(decoded_token.project_id).to eq(nil)
          expect(decoded_token.instance_name).to eq(instance_name_value)
          expect(decoded_token.service_account_id).to eq(sub_value)
          expect(decoded_token.service_account_email).to eq(email_value)
        end
      end

      context "empty project_id claim" do
        subject(:decoded_token) do
          ::Authentication::AuthnGcp::DecodedToken.new(
            decoded_token_hash: decoded_token_hash_empty_project_id,
            logger:             Rails.logger
          )
        end

        it "does not raise an error" do
          expect { decoded_token }.to_not raise_error
        end

        it "parses the token expectedly" do
          expect(decoded_token.project_id).to eq(nil)
          expect(decoded_token.instance_name).to eq(instance_name_value)
          expect(decoded_token.service_account_id).to eq(sub_value)
          expect(decoded_token.service_account_email).to eq(email_value)
        end
      end
    end
  end
end
