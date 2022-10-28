# frozen_string_literal: true

require 'spec_helper'

DatabaseCleaner.strategy = :truncation

describe RolesController, type: :request do
  before do
    Slosilo["authn:rspec"] ||= Slosilo::Key.new
  end

  let(:current_user) { Role.find_or_create(role_id: 'rspec:user:admin') }

  let(:role_url) do
    '/roles/rspec/group/test'
  end

  describe '#add_member' do
    before(:each) do
      payload = <<~YAML
        - !group test
        - !group other
      YAML

      put(
        '/policies/rspec/policy/root',
        env: token_auth_header.merge({ 'RAW_POST_DATA' => payload })
      )
    end

    context 'when the role API extensions are enabled' do
      let(:extension_double) do
        instance_double(Conjur::Extension::Extension)
          .tap do |extension_double|
            allow(extension_double)
              .to receive(:call)
          end
      end

      before do
        allow_any_instance_of(Conjur::FeatureFlags::Features)
          .to receive(:enabled?).with(:roles_api_extensions).and_return(true)

        allow_any_instance_of(Conjur::Extension::Repository)
          .to receive(:extension)
          .with(kind: RolesController::ROLES_API_EXTENSION_KIND)
          .and_return(extension_double)
      end

      it "loads the extension classes" do
        expect_any_instance_of(Conjur::Extension::Repository)
          .to receive(:extension)
          .with(kind: RolesController::ROLES_API_EXTENSION_KIND)

        post("#{role_url}?members&member=rspec:group:other", env: token_auth_header)
      end

      it "emits the expected callbacks" do
        expect(extension_double)
          .to receive(:call)
          .with(:before_add_member, role: anything, member: anything)

        expect(extension_double)
          .to receive(:call)
          .with(:after_add_member, role: anything, member: anything, membership: anything)

        post("#{role_url}?members&member=rspec:group:other", env: token_auth_header)
      end
    end

    context 'when the role API extensions are disabled' do
      before do
        allow_any_instance_of(Conjur::FeatureFlags::Features)
          .to receive(:enabled?).with(:roles_api_extensions).and_return(false)
      end

      it "does not load the extension classes" do
        expect_any_instance_of(Conjur::Extension::Repository)
          .not_to receive(:extension_set)
          .with(RolesController::ROLES_API_EXTENSION_KIND)

        post("#{role_url}?members&member=rspec:group:other", env: token_auth_header)
      end
    end
  end

  describe '#delete_member' do
    before(:each) do
      payload = <<~YAML
        - !group test
        - !group other

        - !grant
          role: !group test
          member: !group other
      YAML

      put(
        '/policies/rspec/policy/root',
        env: token_auth_header.merge({ 'RAW_POST_DATA' => payload })
      )
    end

    context 'when the role API extensions are enabled' do
      let(:extension_double) do
        instance_double(Conjur::Extension::Extension)
          .tap do |extension_double|
            allow(extension_double)
              .to receive(:call)
          end
      end

      before do
        allow_any_instance_of(Conjur::FeatureFlags::Features)
          .to receive(:enabled?).with(:roles_api_extensions).and_return(true)

        allow_any_instance_of(Conjur::Extension::Repository)
          .to receive(:extension)
          .with(kind: RolesController::ROLES_API_EXTENSION_KIND)
          .and_return(extension_double)
      end

      it "loads the extension classes" do
        expect_any_instance_of(Conjur::Extension::Repository)
          .to receive(:extension)
          .with(kind: RolesController::ROLES_API_EXTENSION_KIND)

        delete("#{role_url}?members&member=rspec:group:other", env: token_auth_header)
      end

      it "runs the expected callbacks" do
        expect(extension_double)
          .to receive(:call)
          .with(:before_delete_member, role: anything, member: anything, membership: anything)

        expect(extension_double)
          .to receive(:call)
          .with(:after_delete_member, role: anything, member: anything, membership: anything)

        delete("#{role_url}?members&member=rspec:group:other", env: token_auth_header)
      end
    end

    context 'when the role API extensions are disable' do
      it "does not load the extension classes" do
        expect_any_instance_of(Conjur::Extension::Repository)
          .not_to receive(:extension)
          .with(RolesController::ROLES_API_EXTENSION_KIND)

        delete("#{role_url}?members&member=rspec:group:other", env: token_auth_header)
      end
    end
  end

  let(:token_auth_header) do
    bearer_token = Slosilo["authn:rspec"].signed_token(current_user.login)
    token_auth_str =
      "Token token=\"#{Base64.strict_encode64(bearer_token.to_json)}\""
    { 'HTTP_AUTHORIZATION' => token_auth_str }
  end
end
