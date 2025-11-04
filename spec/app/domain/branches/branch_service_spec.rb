# spec/domain/branch/branch_service_spec.rb
require 'spec_helper'

RSpec.describe(Branches::BranchService) do
  let(:owner_service) { instance_double(Branches::OwnerService) }
  let(:annotation_service) { instance_double(Annotations::AnnotationService) }
  let(:res_service) { instance_double(Resources::ResourceService) }
  let(:res_scopes_service) { instance_double(Resources::ResourceScopesService) }
  let(:role_repo) { class_double(Role) }
  let(:role_membership_repo) { class_double(RoleMembership) }
  let(:secret_repo) { class_double(Secret) }
  let(:logger) { instance_double(Logger, debug?: true, debug: nil) }

  let(:service) do
    described_class.send(:new,
                         owner_service: owner_service,
                         annotation_service: annotation_service,
                         res_service: res_service,
                         res_scopes_service: res_scopes_service,
                         role_repo: role_repo,
                         role_membership_repo: role_membership_repo,
                         secret_repo: secret_repo,
                         logger: logger)
  end

  let(:account) { 'rspec' }
  let(:identifier) { 'data/branch1' }
  let(:role) { instance_double('Role', id: 'role:rspec:branch:data/branch1', allowed_to?: true) }

  let(:owner) { instance_double(Branches::Owner, kind: 'user', id: 'alice', set?: true) }
  let(:annotations) { { 'key1' => 'value1', 'key2' => 'value2' } }

  let(:branch) do
    instance_double(Branches::Branch,
                    name: 'branch1',
                    branch: 'data',
                    owner: owner,
                    annotations: annotations,
                    identifier: identifier)
  end

  let(:policy) do
    instance_double('Policy',
                    id: 'rspec:policy:data/branch1',
                    identifier: 'data/branch1',
                    owner_id: 'rspec:user:alice',
                    policy_id: 'rspec:policy:data',
                    annotations: [])
  end

  describe '#read_and_auth_branch' do
    it 'returns a branch when resource exists and user is authorized' do
      expect(res_service).to receive(:read_and_auth_policy)
        .with(role, 'read', account, identifier)
        .and_return(policy)

      expect(Branches::Branch).to receive(:from_model)
        .with(policy)
        .and_return(branch)

      result = service.read_and_auth_branch(role, 'read', account, identifier)
      expect(result).to eq(branch)
    end

    it 'raises RecordNotFound when resource does not exist' do
      expect(res_service).to receive(:read_and_auth_policy)
        .with(role, 'read', account, identifier)
        .and_raise(Exceptions::RecordNotFound.new("not found"))

      expect { service.read_and_auth_branch(role, 'read', account, identifier) }.to raise_error(Exceptions::RecordNotFound)
    end
  end

  describe '#read_branch' do
    it 'returns a branch when resource exists' do
      expect(res_service).to receive(:read_res)
        .with(role, account, 'policy', identifier)
        .and_return(policy)

      expect(Branches::Branch).to receive(:from_model)
        .with(policy)
        .and_return(branch)

      result = service.read_branch(role, account, identifier)
      expect(result).to eq(branch)
    end

    it 'raises RecordNotFound when resource does not exist' do
      expect(res_service).to receive(:read_res)
        .with(role, account, 'policy', identifier)
        .and_raise(Exceptions::RecordNotFound.new("not found"))

      expect { service.read_branch(role, account, identifier) }.to raise_error(Exceptions::RecordNotFound)
    end
  end

  describe '#get_branch' do
    it 'returns a branch when resource exists' do
      expect(res_service).to receive(:get_res)
        .with(account, 'policy', identifier)
        .and_return(policy)

      expect(Branches::Branch).to receive(:from_model)
        .with(policy)
        .and_return(branch)

      result = service.get_branch(account, identifier)
      expect(result).to eq(branch)
    end

    it 'raises RecordNotFound when resource does not exist' do
      expect(res_service).to receive(:get_res)
        .with(account, 'policy', identifier)
        .and_raise(Exceptions::RecordNotFound.new("not found"))

      expect { service.get_branch(account, identifier) }.to raise_error(Exceptions::RecordNotFound)
    end
  end

  describe '#fetch_branch' do
    it 'returns a branch when resource exists' do
      expect(res_service).to receive(:fetch_res)
        .with(account, 'policy', identifier)
        .and_return(policy)

      expect(Branches::Branch).to receive(:from_model)
        .with(policy)
        .and_return(branch)

      result = service.fetch_branch(account, identifier)
      expect(result).to eq(branch)
    end

    it 'returns nil when resource does not exist' do
      expect(res_service).to receive(:fetch_res)
        .with(account, 'policy', identifier)
        .and_return(nil)

      result = service.fetch_branch(account, identifier)
      expect(result).to be_nil
    end
  end

  describe '#check_parent_branch_exists' do
    context 'with root branch' do
      let(:root_identifier) { '/' }

      it 'returns nil' do
        allow(service).to receive(:root?).with(root_identifier).and_return(true)

        result = service.check_parent_branch_exists(account, root_identifier)
        expect(result).to be_nil
      end
    end

    context 'with non-root branch' do
      it 'calls get_branch with parent identifier' do
        allow(service).to receive(:root?).with(identifier).and_return(false)
        allow(service).to receive(:parent_identifier).with(identifier).and_return('data')

        expect(service).to receive(:get_branch).with(account, 'data')
        service.check_parent_branch_exists(account, identifier)
      end
    end
  end

  describe '#create_branch' do
    let(:branch_id) { 'rspec:policy:data/branch1' }
    let(:owner_id) { 'rspec:user:alice' }
    let(:policy_id) { 'rspec:policy:data' }
    let(:role_instance) { instance_double('Role', save: true) }
    let(:role_membership_instance) { instance_double('RoleMembership', save: true) }
    let(:annotation_instance) { instance_double('Annotation', save: true) }

    before do
      allow(service).to receive(:full_id).with(account, 'policy', branch.identifier).and_return(branch_id)
      allow(service).to receive(:res_owner_id).with(account, branch.branch, branch.owner).and_return(owner_id)
      allow(service).to receive(:full_id).with(account, 'policy', 'data').and_return(policy_id)

      allow(res_service).to receive(:save_res).with(policy_id, owner_id, branch_id).and_return(policy)
      allow(role_repo).to receive(:create).with(role_id: branch_id, policy_id: policy_id).and_return(role_instance)
      allow(role_membership_repo).to receive(:create).with(
        role_id: branch_id,
        member_id: owner_id,
        policy_id: policy_id,
        admin_option: true,
        ownership: true
      ).and_return(role_membership_instance)

      allow(annotation_service).to receive(:create_annotation).and_return(annotation_instance)
      allow(Branches::Branch).to receive(:from_model).with(policy).and_return(branch)
    end

    it 'creates a new branch' do
      expect(res_service).to receive(:save_res).with(policy_id, owner_id, branch_id)
      expect(role_repo).to receive(:create).with(role_id: branch_id, policy_id: policy_id)
      expect(role_membership_repo).to receive(:create).with(
        role_id: branch_id,
        member_id: owner_id,
        policy_id: policy_id,
        admin_option: true,
        ownership: true
      )

      result = service.create_branch(account, branch)
      expect(result).to eq(branch)
    end

    it 'creates annotations for the branch' do
      expect(annotation_service).to receive(:create_annotation).with(branch_id, 'key1', 'value1', policy_id)
      expect(annotation_service).to receive(:create_annotation).with(branch_id, 'key2', 'value2', policy_id)

      service.create_branch(account, branch)
    end
  end

  describe '#update_branch' do
    let(:branch_up_part) do
      instance_double(Branches::BranchUpPart,
                      owner: owner,
                      annotations: annotations)
    end

    before do
      allow(service).to receive(:get_branch_pol).with(account, identifier).and_return(policy)
      allow(service).to receive(:fetch_branch).with(account, policy.identifier).and_return(branch)
    end

    it 'updates the branch and returns it' do
      expect(service).to receive(:update_owner).with(account, policy, owner)
      expect(service).to receive(:update_annotations).with(policy, annotations)

      result = service.update_branch(account, branch_up_part, identifier)
      expect(result).to eq(branch)
    end

    it 'does not update owner if owner is not set' do
      allow(owner).to receive(:set?).and_return(false)

      expect(service).not_to receive(:update_owner)
      expect(service).to receive(:update_annotations)

      service.update_branch(account, branch_up_part, identifier)
    end

    it 'does not update annotations if annotations are empty' do
      allow(branch_up_part).to receive(:annotations).and_return({})

      expect(service).to receive(:update_owner)
      expect(service).not_to receive(:update_annotations)

      service.update_branch(account, branch_up_part, identifier)
    end
  end

  describe '#check_branch_not_conflict' do
    context 'when branch does not exist' do
      before do
        allow(service).to receive(:fetch_branch).with(account, identifier).and_return(nil)
      end

      it 'returns nil' do
        result = service.check_branch_not_conflict(account, identifier)
        expect(result).to be_nil
      end
    end

    context 'when branch exists' do
      before do
        allow(service).to receive(:fetch_branch).with(account, identifier).and_return(branch)
        allow(service).to receive(:full_id).with(account, 'branch', identifier).and_return('rspec:branch:data/branch1')
      end

      it 'raises RecordExists error' do
        expect { service.check_branch_not_conflict(account, identifier) }.to raise_error(Exceptions::RecordExists)
      end
    end
  end

  describe '#read_branches' do
    let(:paging) { { limit: 10, offset: 0 } }
    let(:base_scope) { double('base_scope', count: 2) }
    let(:paginated_scope) { double('paginated_scope') }
    let(:eager_scope1) { double('eager_scope1') }
    let(:eager_scope2) { double('eager_scope2') }
    let(:policies) { [policy, policy] }
    let(:branches) { [branch, branch] }

    before do
      allow(res_scopes_service).to receive(:visible_resources_scope)
        .with(account, role.id, identifier)
        .and_return(base_scope)

      allow(res_scopes_service).to receive(:paginate_scope)
        .with(paging, base_scope)
        .and_return(paginated_scope)

      # Create a proper chain of doubles for the sequential method calls
      allow(paginated_scope).to receive(:eager)
        .with(owner: an_instance_of(Proc))
        .and_return(eager_scope1)

      allow(eager_scope1).to receive(:eager)
        .with(:annotations)
        .and_return(eager_scope2)

      allow(eager_scope2).to receive(:all)
        .and_return(policies)

      allow(Branches::Branch).to receive(:from_model).and_return(branch, branch)
    end

    it 'returns branches and count' do
      result = service.read_branches(role.id, account, paging, identifier)
      expect(result[:branches]).to eq(branches)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#delete_branch' do
    let(:resources) { [policy] }
    let(:secrets) { [instance_double('Secret', delete: true)] }
    let(:annotations_list) { [instance_double('Annotation', delete: true)] }
    let(:base_scope) { instance_double('Sequel::Dataset') }
    let(:role) { instance_double('Sequel::Role') }

    before do
      allow(res_scopes_service).to receive(:resources_to_del_scope)
        .with(account, identifier)
        .and_return(base_scope)

      allow(base_scope).to receive(:order).and_return(base_scope)
      allow(base_scope).to receive(:all).and_return(resources)

      allow(policy).to receive(:secrets).and_return(secrets)
      allow(policy).to receive(:kind).and_return('policy')
      allow(policy).to receive(:annotations).and_return(annotations_list)
      allow(policy).to receive(:destroy).and_return(true)

      allow(role).to receive(:id).and_return("rspec:policy:data/branch1")
      allow(role).to receive(:destroy).and_return(true)
      allow(role).to receive(:allowed_to?).with(:update, policy).and_return(true)

      allow(role_repo).to receive(:[]).with("rspec:policy:data/branch1").and_return(role)
    end

    it 'deletes the branch and associated resources' do
      service.delete_branch(account, role, identifier)

      expect(secrets.first).to have_received(:delete)
      expect(annotations_list.first).to have_received(:delete)
      expect(policy).to have_received(:destroy)
      expect(role).to have_received(:destroy)
    end

    context 'when user is not allowed to update' do
      before do
        allow(role).to receive(:allowed_to?).with(:update, policy).and_return(false)
        allow(service).to receive(:full_id).with(account, 'policy', policy.identifier).and_return('rspec:branch:data/branch1')
      end

      it 'raises RecordNotFound error' do
        expect { service.delete_branch(account, role, identifier) }.to raise_error(Exceptions::RecordNotFound)
      end
    end
  end

  describe '#delete_branch that has itself as owner' do
    let(:resources) { [policy] }
    let(:secrets) { [instance_double('Secret', delete: true)] }
    let(:annotations_list) { [instance_double('Annotation', delete: true)] }
    let(:base_scope) { instance_double('Sequel::Dataset') }

    before do
      allow(policy).to receive(:owner_id).and_return(policy.id)
      allow(res_scopes_service).to receive(:resources_to_del_scope)
        .with(account, identifier)
        .and_return(base_scope)

      allow(base_scope).to receive(:order).and_return(base_scope)
      allow(base_scope).to receive(:all).and_return(resources)

      allow(policy).to receive(:secrets).and_return(secrets)
      allow(policy).to receive(:kind).and_return('policy')
      allow(policy).to receive(:annotations).and_return(annotations_list)
      allow(policy).to receive(:destroy).and_return(true)

      allow(role).to receive(:id).and_return("rspec:policy:data/branch1")
      allow(role).to receive(:destroy).and_return(true)
      allow(role).to receive(:allowed_to?).with(:update, policy).and_return(true)

      allow(role_repo).to receive(:[]).with("rspec:policy:data/branch1").and_return(role)
    end

    it 'deletes the branch and associated resources' do
      service.delete_branch(account, role, identifier)

      expect(secrets.first).to have_received(:delete)
      expect(annotations_list.first).to have_received(:delete)
      expect(policy).to have_received(:destroy)
      expect(role).to have_received(:destroy)
    end

    context 'when user is not allowed to update' do
      before do
        allow(role).to receive(:allowed_to?).with(:update, policy).and_return(false)
        allow(service).to receive(:full_id).with(account, 'policy', policy.identifier).and_return('rspec:branch:data/branch1')
      end

      it 'raises RecordNotFound error' do
        expect { service.delete_branch(account, role, identifier) }.to raise_error(Exceptions::RecordNotFound)
      end
    end
  end
end
