# spec/domain/annotation/annotation_service_spec.rb
require 'spec_helper'

RSpec.describe(Annotations::AnnotationService) do
  let(:annotation_repo) { class_double('::Annotation') }
  let(:logger) { instance_double(Logger, debug?: true, debug: nil) }
  let(:service) { described_class.send(:new, annotation_repo: annotation_repo, logger: logger) }

  let(:resource_id) { 'policy:rspec:branch:data/branch1' }
  let(:name) { 'key1' }
  let(:value) { 'value1' }
  let(:policy_id) { 'policy:rspec:policy:data' }
  let(:annotation_instance) { instance_double('Annotation', save: true, update: true, destroy: true) }

  describe '#fetch_annotation' do
    it 'returns the annotation if found' do
      expect(annotation_repo).to receive(:where).with(resource_id: resource_id, name: name.to_s).and_return([annotation_instance])
      expect(service.fetch_annotation(resource_id, name)).to eq(annotation_instance)
    end

    it 'returns nil if not found' do
      expect(annotation_repo).to receive(:where).with(resource_id: resource_id, name: name.to_s).and_return([nil])
      expect(service.fetch_annotation(resource_id, name)).to be_nil
    end
  end

  describe '#create_annotation' do
    it 'creates and saves a new annotation' do
      expect(annotation_repo).to receive(:create).with(resource_id: resource_id, name: name, value: value, policy_id: policy_id).and_return(annotation_instance)
      expect(annotation_instance).to receive(:save)
      service.create_annotation(resource_id, name, value, policy_id)
    end
  end

  describe '#upsert_annotation' do
    it 'creates annotation if not found' do
      expect(service).to receive(:fetch_annotation).with(resource_id, name).and_return(nil)
      expect(service).to receive(:create_annotation).with(resource_id, name, value, policy_id)
      service.upsert_annotation(resource_id, policy_id, name, value)
    end

    it 'updates annotation if found' do
      expect(service).to receive(:fetch_annotation).with(resource_id, name).and_return(annotation_instance)
      expect(annotation_instance).to receive(:update).with(value: value)
      service.upsert_annotation(resource_id, policy_id, name, value)
    end
  end

  describe '#delete_annotation' do
    it 'destroys annotation if found' do
      expect(service).to receive(:fetch_annotation).with(resource_id, name).and_return(annotation_instance)
      expect(annotation_instance).to receive(:destroy)
      service.delete_annotation(resource_id, name)
    end

    it 'raises if annotation not found' do
      expect(service).to receive(:fetch_annotation).with(resource_id, name).and_return(nil)
      expect { service.delete_annotation(resource_id, name) }.to raise_error(ApplicationController::RecordNotFound)
    end
  end
end
