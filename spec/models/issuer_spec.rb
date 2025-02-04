# frozen_string_literal: true

require 'spec_helper'

describe Issuer do
  subject do
    Issuer.create(
      issuer_id: issuer_id,
      issuer_type: issuer_type,
      data: data_json,
      account: account,
      max_ttl: max_ttl,
      modified_at: Time.now,
      policy: policy
    )
  end

  let(:issuer_id) { 'test_id' }
  let(:issuer_type) { 'test_issuer_type' }
  let(:data_json) { data.to_json }
  let(:data) do
    { 'value' => 'test' }
  end
  let(:account) { "spec" }
  let(:max_ttl) { 600 }

  let(:policy) do
    Resource.create(
      resource_id: "#{account}:policy:test",
      owner: owner
    )
  end
  let(:owner) { Role.create(role_id: "#{account}:user:spec") }

  describe '#as_json' do
    it 'returns the expected JSON' do
      expect(subject.as_json).to include({
        id: issuer_id,
        type: issuer_type,
        data: data,
        account: account,
        max_ttl: max_ttl
      })
    end
  end

  describe '#delete_issuer_variables' do
    let(:variable_resource_id) do
      "#{account}:variable:#{Issuer::DYNAMIC_VARIABLE_PREFIX}test"
    end

    before do
      # Create an associated variable with the issuer annotation
      Resource.create(
        resource_id: variable_resource_id,
        owner: owner
      )

      Annotation.create(
        resource_id: variable_resource_id,
        name: "#{Issuer::DYNAMIC_ANNOTATION_PREFIX}issuer",
        value: issuer_id
      )
    end

    it 'deletes the variables associated with the issuer' do
      subject.delete_issuer_variables

      # The resource and its annotations should be deleted
      expect(Resource[variable_resource_id]).to be_nil
      expect(Annotation.where(resource_id: variable_resource_id)).to be_empty
    end
  end

  describe '#issuer_variables_exist?' do
    context 'when there are no variables' do
      it 'returns false' do
        expect(subject.issuer_variables_exist?).to be(false)
      end
    end

    context 'when there are variables' do
      before do
        # Create an associated variable with the issuer annotation
        Resource.create(
          resource_id: "#{account}:variable:#{Issuer::DYNAMIC_VARIABLE_PREFIX}test",
          owner: owner
        )

        Annotation.create(
          resource_id: "#{account}:variable:#{Issuer::DYNAMIC_VARIABLE_PREFIX}test",
          name: "#{Issuer::DYNAMIC_ANNOTATION_PREFIX}issuer",
          value: issuer_id
        )
      end

      it 'returns true' do
        expect(subject.issuer_variables_exist?).to be(true)
      end
    end
  end
end
