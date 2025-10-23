# frozen_string_literal: true

require 'spec_helper'

# Sample raw diff row data captured from spec/models/loader/dryrun_diff_spec

rawdiff_annotations1 = [
  { resource_id: "rspec:group:example/alpha/secret-users", name: "key", value: "value", policy_id: "rspec:policy:root" },
  { resource_id: "rspec:user:alice@example", name: "key", value: "value", policy_id: "rspec:policy:root" },
  { resource_id: "rspec:user:annie@example", name: "key", value: "value", policy_id: "rspec:policy:root" }
]

rawdiff_annotations2 = [
  { resource_id: "rspec:group:example/omega/secret-users", name: "key", value: "value", policy_id: "rspec:policy:root" },
  { resource_id: "rspec:user:barrett@example", name: "key", value: "value", policy_id: "rspec:policy:root" }
]

rawdiff_permissions1 = [
  { privilege: "read", resource_id: "rspec:variable:example/omega/secret01", role_id: "rspec:group:example/omega/secret-users", policy_id: "rspec:policy:root" },
  { privilege: "execute", resource_id: "rspec:variable:example/omega/secret02", role_id: "rspec:group:example/omega/secret-users", policy_id: "rspec:policy:root" }
]

rawdiff_permissions2 = [
  { privilege: "read", resource_id: "rspec:variable:example/omega/secret02", role_id: "rspec:group:example/omega/secret-users", policy_id: "rspec:policy:root" }
]

rawdiff_resources1 = [
  { resource_id: "rspec:group:example/alpha/secret-users", owner_id: "rspec:policy:example/alpha", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" }
]

rawdiff_resources2 = [
  { resource_id: "rspec:variable:example/alpha/secret02", owner_id: "rspec:policy:example/alpha", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" },
  { resource_id: "rspec:variable:example/omega/secret01", owner_id: "rspec:policy:example/omega", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" },
  { resource_id: "rspec:variable:example/omega/secret02", owner_id: "rspec:policy:example/omega", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" }
]

rawdiff_role_memberships1 = [
  { role_id: "rspec:group:example/alpha/secret-users", member_id: "rspec:policy:example/alpha", admin_option: true, ownership: true, policy_id: "rspec:policy:root" },
  { role_id: "rspec:group:example/alpha/secret-users", member_id: "rspec:user:annie@example", admin_option: false, ownership: false, policy_id: "rspec:policy:root" }
]

rawdiff_role_memberships2 = [
  { role_id: "rspec:group:example/omega/secret-users", member_id: "rspec:user:barrett@example", admin_option: false, ownership: false, policy_id: "rspec:policy:root" },
  { role_id: "rspec:policy:example", member_id: "rspec:user:admin", admin_option: true, ownership: true, policy_id: "rspec:policy:root" },
  { role_id: "rspec:policy:example/alpha", member_id: "rspec:user:alice@example", admin_option: true, ownership: true, policy_id: "rspec:policy:root" }
]

rawdiff_roles1 = [
  { role_id: "rspec:group:example/alpha/secret-users", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" },
  { role_id: "rspec:group:example/omega/secret-users", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" }
]

rawdiff_roles2 = [
  { role_id: "rspec:user:alice@example", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" },
  { role_id: "rspec:user:annie@example", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" },
  { role_id: "rspec:user:barrett@example", created_at: '2024-10-10 18:38:01.036001 +0000', policy_id: "rspec:policy:root" }
]

rawdiff_credentials1 = [
  { role_id: "rspec:user:barrett@example", client_id: nil, restricted_to: ['#<IPAddr: IPv4:127.0.0.1/255.255.255.255>'] },
  { role_id: "rspec:user:bob@foo-bar", client_id: nil, restricted_to: ['#<IPAddr: IPv4:127.0.0.1/255.255.255.255>', '#<IPAddr: IPv4:10.0.0.0/255.255.255.0>'] }
]

rawdiff_credentials2 = [
  { role_id: "rspec:user:bob@foo-bar", client_id: nil, restricted_to: ['#<IPAddr: IPv4:127.0.0.1/255.255.255.255>', '#<IPAddr: IPv4:10.0.0.0/255.255.255.0>'] }
]

describe Loader::DryRun do
  context "when diff elements DTOs are initialized" do
    let(:dto_sample1) { DB::Repository::DataObjects::DiffElements.new }
    let(:dto_sample2) { DB::Repository::DataObjects::DiffElements.new }

    it "tables should be empty" do
      expect(dto_sample1.roles).to be(nil)
      expect(dto_sample1.resources).to be(nil)
      expect(dto_sample1.role_memberships).to be(nil)
      expect(dto_sample1.permissions).to be(nil)
      expect(dto_sample1.annotations).to be(nil)
      expect(dto_sample1.credentials).to be(nil)

      expect(dto_sample2.roles).to be(nil)
      expect(dto_sample2.resources).to be(nil)
      expect(dto_sample2.role_memberships).to be(nil)
      expect(dto_sample2.permissions).to be(nil)
      expect(dto_sample2.annotations).to be(nil)
      expect(dto_sample2.credentials).to be(nil)
    end

    it 'tables should accept row assignments as independent instances' do
      # => need to capture a few sample rows of each kind
      dto_sample1.roles = rawdiff_roles1
      dto_sample1.resources = rawdiff_resources1
      dto_sample1.role_memberships = rawdiff_role_memberships1
      dto_sample1.permissions = rawdiff_permissions1
      dto_sample1.annotations = rawdiff_annotations1
      dto_sample1.credentials = rawdiff_credentials1

      dto_sample2.roles = rawdiff_roles2
      dto_sample2.resources = rawdiff_resources2
      dto_sample2.role_memberships = rawdiff_role_memberships2
      dto_sample2.permissions = rawdiff_permissions2
      dto_sample2.annotations = rawdiff_annotations2
      dto_sample2.credentials = rawdiff_credentials2

      expect(dto_sample1.roles.length).to be == 2
      expect(dto_sample1.resources.length).to be == 1
      expect(dto_sample1.role_memberships.length).to be == 2
      expect(dto_sample1.permissions.length).to be == 2
      expect(dto_sample1.annotations.length).to be == 3
      expect(dto_sample1.credentials.length).to be == 2

      expect(dto_sample2.roles.length).to be == 3
      expect(dto_sample2.resources.length).to be == 3
      expect(dto_sample2.role_memberships.length).to be == 3
      expect(dto_sample2.permissions.length).to be == 1
      expect(dto_sample2.annotations.length).to be == 2
      expect(dto_sample2.credentials.length).to be == 1
    end

    it 'tables should accept reassignment, with new data overwriting existing' do
      dto_sample1.roles = rawdiff_roles2
      dto_sample2.roles = rawdiff_roles2
      expect(dto_sample1.roles.length).to be == 3
      expect(dto_sample2.roles.length).to be == 3

      dto_sample1.resources = rawdiff_resources2
      dto_sample2.resources = rawdiff_resources2
      expect(dto_sample1.resources.length).to be == 3
      expect(dto_sample2.resources.length).to be == 3

      dto_sample1.role_memberships = rawdiff_role_memberships2
      dto_sample2.role_memberships = rawdiff_role_memberships2
      expect(dto_sample1.role_memberships.length).to be == 3
      expect(dto_sample2.role_memberships.length).to be == 3

      dto_sample1.permissions = rawdiff_permissions2
      dto_sample2.permissions = rawdiff_permissions2
      expect(dto_sample1.permissions.length).to be == 1
      expect(dto_sample2.permissions.length).to be == 1

      dto_sample1.annotations = rawdiff_annotations2
      dto_sample2.annotations = rawdiff_annotations2
      expect(dto_sample1.annotations.length).to be == 2
      expect(dto_sample2.annotations.length).to be == 2

      dto_sample1.credentials = rawdiff_credentials2
      dto_sample2.credentials = rawdiff_credentials2
      expect(dto_sample1.credentials.length).to be == 1
      expect(dto_sample2.credentials.length).to be == 1
    end
  end
end
