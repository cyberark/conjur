# frozen_string_literal: true

require 'spec_helper'

# Sample raw diff row data captured from spec/models/loader/dryrun_diff_spec

rawdiff_annotations_1 = [
  {:resource_id=>"rspec:group:example/alpha/secret-users", :name=>"key", :value=>"value", :policy_id=>"rspec:policy:root"},
  {:resource_id=>"rspec:user:alice@example", :name=>"key", :value=>"value", :policy_id=>"rspec:policy:root"},
  {:resource_id=>"rspec:user:annie@example", :name=>"key", :value=>"value", :policy_id=>"rspec:policy:root"},
]

rawdiff_annotations_2 = [
  {:resource_id=>"rspec:group:example/omega/secret-users", :name=>"key", :value=>"value", :policy_id=>"rspec:policy:root"},
  {:resource_id=>"rspec:user:barrett@example", :name=>"key", :value=>"value", :policy_id=>"rspec:policy:root"}
]

rawdiff_permissions_1 = [
  {:privilege=>"read", :resource_id=>"rspec:variable:example/omega/secret01", :role_id=>"rspec:group:example/omega/secret-users", :policy_id=>"rspec:policy:root"},
  {:privilege=>"execute", :resource_id=>"rspec:variable:example/omega/secret02", :role_id=>"rspec:group:example/omega/secret-users", :policy_id=>"rspec:policy:root"}
]

rawdiff_permissions_2 = [
  {:privilege=>"read", :resource_id=>"rspec:variable:example/omega/secret02", :role_id=>"rspec:group:example/omega/secret-users", :policy_id=>"rspec:policy:root"}
]

rawdiff_resources_1 = [
  {:resource_id=>"rspec:group:example/alpha/secret-users", :owner_id=>"rspec:policy:example/alpha", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"}
]

rawdiff_resources_2 = [
  {:resource_id=>"rspec:variable:example/alpha/secret02", :owner_id=>"rspec:policy:example/alpha", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"},
  {:resource_id=>"rspec:variable:example/omega/secret01", :owner_id=>"rspec:policy:example/omega", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"},
  {:resource_id=>"rspec:variable:example/omega/secret02", :owner_id=>"rspec:policy:example/omega", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"}
]

rawdiff_role_memberships_1 = [
  {:role_id=>"rspec:group:example/alpha/secret-users", :member_id=>"rspec:policy:example/alpha", :admin_option=>true, :ownership=>true, :policy_id=>"rspec:policy:root"},
  {:role_id=>"rspec:group:example/alpha/secret-users", :member_id=>"rspec:user:annie@example", :admin_option=>false, :ownership=>false, :policy_id=>"rspec:policy:root"}
]

rawdiff_role_memberships_2 = [
  {:role_id=>"rspec:group:example/omega/secret-users", :member_id=>"rspec:user:barrett@example", :admin_option=>false, :ownership=>false, :policy_id=>"rspec:policy:root"},
  {:role_id=>"rspec:policy:example", :member_id=>"rspec:user:admin", :admin_option=>true, :ownership=>true, :policy_id=>"rspec:policy:root"},
  {:role_id=>"rspec:policy:example/alpha", :member_id=>"rspec:user:alice@example", :admin_option=>true, :ownership=>true, :policy_id=>"rspec:policy:root"}
]

rawdiff_roles_1 = [
  {:role_id=>"rspec:group:example/alpha/secret-users", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"},
  {:role_id=>"rspec:group:example/omega/secret-users", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"}
]

rawdiff_roles_2 = [
  {:role_id=>"rspec:user:alice@example", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"},
  {:role_id=>"rspec:user:annie@example", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"},
  {:role_id=>"rspec:user:barrett@example", :created_at=>'2024-10-10 18:38:01.036001 +0000', :policy_id=>"rspec:policy:root"}
]

rawdiff_credentials_1 = [
  {:role_id=>"rspec:user:barrett@example", :client_id=>nil, :restricted_to=>['#<IPAddr: IPv4:127.0.0.1/255.255.255.255>']},
  {:role_id=>"rspec:user:bob@foo-bar", :client_id=>nil, :restricted_to=>['#<IPAddr: IPv4:127.0.0.1/255.255.255.255>', '#<IPAddr: IPv4:10.0.0.0/255.255.255.0>']}
]

rawdiff_credentials_2 = [
  {:role_id=>"rspec:user:bob@foo-bar", :client_id=>nil, :restricted_to=>['#<IPAddr: IPv4:127.0.0.1/255.255.255.255>', '#<IPAddr: IPv4:10.0.0.0/255.255.255.0>']}
]


describe Loader::DryRun do
  context "when diff elements DTOs are initialized" do

    it "tables should be empty" do
      dto_sample_1 = Loader::DiffElementsDTO.new
      dto_sample_2 = Loader::DiffElementsDTO.new

      expect(dto_sample_1.roles).to be(nil)
      expect(dto_sample_1.resources).to be(nil)
      expect(dto_sample_1.role_memberships).to be(nil)
      expect(dto_sample_1.permissions).to be(nil)
      expect(dto_sample_1.annotations).to be(nil)
      expect(dto_sample_1.credentials).to be(nil)

      expect(dto_sample_2.roles).to be(nil)
      expect(dto_sample_2.resources).to be(nil)
      expect(dto_sample_2.role_memberships).to be(nil)
      expect(dto_sample_2.permissions).to be(nil)
      expect(dto_sample_2.annotations).to be(nil)
      expect(dto_sample_2.credentials).to be(nil)
    end

    it 'tables should accept row assignments as independent instances' do
      # => need to capture a few sample rows of each kind
      dto_sample_1 = Loader::DiffElementsDTO.new
      dto_sample_2 = Loader::DiffElementsDTO.new

      dto_sample_1.roles = rawdiff_roles_1
      dto_sample_1.resources = rawdiff_resources_1
      dto_sample_1.role_memberships = rawdiff_role_memberships_1
      dto_sample_1.permissions = rawdiff_permissions_1
      dto_sample_1.annotations = rawdiff_annotations_1
      dto_sample_1.credentials = rawdiff_credentials_1

      dto_sample_2.roles = rawdiff_roles_2
      dto_sample_2.resources = rawdiff_resources_2
      dto_sample_2.role_memberships = rawdiff_role_memberships_2
      dto_sample_2.permissions = rawdiff_permissions_2
      dto_sample_2.annotations = rawdiff_annotations_2
      dto_sample_2.credentials = rawdiff_credentials_2

      expect(dto_sample_1.roles.length).to be == 2
      expect(dto_sample_1.resources.length).to be == 1
      expect(dto_sample_1.role_memberships.length).to be == 2
      expect(dto_sample_1.permissions.length).to be == 2
      expect(dto_sample_1.annotations.length).to be == 3
      expect(dto_sample_1.credentials.length).to be == 2

      expect(dto_sample_2.roles.length).to be == 3
      expect(dto_sample_2.resources.length).to be == 3
      expect(dto_sample_2.role_memberships.length).to be == 3
      expect(dto_sample_2.permissions.length).to be == 1
      expect(dto_sample_2.annotations.length).to be == 2
      expect(dto_sample_2.credentials.length).to be == 1
    end

    it 'tables should accept reassignment, with new data overwriting existing' do
      dto_sample_1 = Loader::DiffElementsDTO.new
      dto_sample_2 = Loader::DiffElementsDTO.new

      dto_sample_1.roles = rawdiff_roles_2
      dto_sample_2.roles = rawdiff_roles_2
      expect(dto_sample_1.roles.length).to be == 3
      expect(dto_sample_2.roles.length).to be == 3

      dto_sample_1.resources = rawdiff_resources_2
      dto_sample_2.resources = rawdiff_resources_2
      expect(dto_sample_1.resources.length).to be == 3
      expect(dto_sample_2.resources.length).to be == 3

      dto_sample_1.role_memberships = rawdiff_role_memberships_2
      dto_sample_2.role_memberships = rawdiff_role_memberships_2
      expect(dto_sample_1.role_memberships.length).to be == 3
      expect(dto_sample_2.role_memberships.length).to be == 3

      dto_sample_1.permissions = rawdiff_permissions_2
      dto_sample_2.permissions = rawdiff_permissions_2
      expect(dto_sample_1.permissions.length).to be == 1
      expect(dto_sample_2.permissions.length).to be == 1

      dto_sample_1.annotations = rawdiff_annotations_2
      dto_sample_2.annotations = rawdiff_annotations_2
      expect(dto_sample_1.annotations.length).to be == 2
      expect(dto_sample_2.annotations.length).to be == 2

      dto_sample_1.credentials = rawdiff_credentials_2
      dto_sample_2.credentials = rawdiff_credentials_2
      expect(dto_sample_1.credentials.length).to be == 1
      expect(dto_sample_2.credentials.length).to be == 1
    end
  end
end
