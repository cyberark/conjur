# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity') do

  let(:identity_empty) { '' }
  let(:identity_nil) { nil }
  let(:identity_without_delimiter) { 'host-test' }
  let(:identity_starts_with_delimiter) { '/host-test' }
  let(:identity_with_multiple_delimiter) { '/apps/sub-apps/host-test' }
  let(:prefix_empty) { '' }
  let(:prefix_nil) { nil }
  let(:delimiter) { '/' }
  let(:prefix_without_delimiter) { 'prefix' }
  let(:prefix_starts_with_delimiter) { '/prefix' }
  let(:prefix_ends_with_delimiter) { 'prefix/' }
  let(:prefix_with_multiple_delimiter) { '/prefix0/prefix1/prefix2' }

  #  ____  _   _  ____    ____  ____  ___  ____  ___
  # (_  _)( )_( )( ___)  (_  _)( ___)/ __)(_  _)/ __)
  #   )(   ) _ (  )__)     )(   )__) \__ \  )(  \__ \
  #  (__) (_) (_)(____)   (__) (____)(___/ (__) (___/

  context "Invalid input" do
    context "With empty identity" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
          identity_prefix: prefix_without_delimiter,
          identity: identity_empty
        )
      end

      it "raises error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingIdentity)
      end
    end

    context "With nil identity" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
          identity_prefix: prefix_without_delimiter,
          identity: identity_nil
        )
      end

      it "raises error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingIdentity)
      end
    end

    context "With empty prefix" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
          identity_prefix: prefix_empty,
          identity: identity_without_delimiter
        )
      end

      it "raises error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingIdentityPrefix)
      end
    end

    context "With nil prefix" do
      subject do
        ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
          identity_prefix: prefix_nil,
          identity: identity_without_delimiter
        )
      end

      it "raises error" do
        expect { subject }.to raise_error(Errors::Authentication::AuthnJwt::MissingIdentityPrefix)
      end
    end
  end

  context "Prefix input" do
    context "with just delimiter value" do
      context "when identity with just delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: delimiter,
            identity: delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(delimiter)
        end
      end

      context "when identity input without delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: delimiter,
            identity: identity_without_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(delimiter + identity_without_delimiter)
        end
      end

      context "when identity starts with delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: delimiter,
            identity: identity_starts_with_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(identity_starts_with_delimiter)
        end
      end

      context "when identity with multiple delimiter" do
          subject do
            ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
              identity_prefix: delimiter,
              identity: identity_with_multiple_delimiter
            )
          end

          it "returns calculated identity with prefix" do
            expect(subject).to eql(identity_with_multiple_delimiter)
          end
        end
    end

    context "without delimiter value" do
      context "when identity with just delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_without_delimiter,
            identity: delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_without_delimiter + delimiter)
        end
      end

      context "when identity input without delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_without_delimiter,
            identity: identity_without_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_without_delimiter + delimiter + identity_without_delimiter)
        end
      end

      context "when identity starts with delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_without_delimiter,
            identity: identity_starts_with_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_without_delimiter + identity_starts_with_delimiter)
        end
      end

      context "when identity with multiple delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_without_delimiter,
            identity: identity_with_multiple_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_without_delimiter + identity_with_multiple_delimiter)
        end
      end
    end

    context "starts with delimiter value" do
      context "when identity with just delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_starts_with_delimiter,
            identity: delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_starts_with_delimiter + delimiter)
        end
      end

      context "when identity input without delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_starts_with_delimiter,
            identity: identity_without_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_starts_with_delimiter + delimiter + identity_without_delimiter)
        end
      end

      context "when identity starts with delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_starts_with_delimiter,
            identity: identity_starts_with_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_starts_with_delimiter + identity_starts_with_delimiter)
        end
      end

      context "when identity with multiple delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_starts_with_delimiter,
            identity: identity_with_multiple_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_starts_with_delimiter + identity_with_multiple_delimiter)
        end
      end
    end

    context "ends with delimiter value" do
      context "when identity with just delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_ends_with_delimiter,
            identity: delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_ends_with_delimiter)
        end
      end

      context "when identity input without delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_ends_with_delimiter,
            identity: identity_without_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_ends_with_delimiter + identity_without_delimiter)
        end
      end

      context "when identity starts with delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_ends_with_delimiter,
            identity: identity_starts_with_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_ends_with_delimiter + identity_starts_with_delimiter[1..-1])
        end
      end

      context "when identity with multiple delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_ends_with_delimiter,
            identity: identity_with_multiple_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_ends_with_delimiter + identity_with_multiple_delimiter[1..-1])
        end
      end
    end

    context "starts multiple delimiter value" do
      context "when identity with just delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_with_multiple_delimiter,
            identity: delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_with_multiple_delimiter + delimiter)
        end
      end

      context "when identity input without delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_with_multiple_delimiter,
            identity: identity_without_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_with_multiple_delimiter + delimiter + identity_without_delimiter)
        end
      end

      context "when identity starts with delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_with_multiple_delimiter,
            identity: identity_starts_with_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_with_multiple_delimiter + identity_starts_with_delimiter)
        end
      end

      context "when identity with multiple delimiter" do
        subject do
          ::Authentication::AuthnJwt::IdentityProviders::AddPrefixToIdentity.new.call(
            identity_prefix: prefix_with_multiple_delimiter,
            identity: identity_with_multiple_delimiter
          )
        end

        it "returns calculated identity with prefix" do
          expect(subject).to eql(prefix_with_multiple_delimiter + identity_with_multiple_delimiter)
        end
      end
    end
  end
end
