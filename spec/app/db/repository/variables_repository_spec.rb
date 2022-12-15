# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('DB::Repository::VariablesRepository') do
  let(:variable_repository) { DB::Repository::VariablesRepository.new }

  describe '.find_by_id_path' do
    before(:each) do
      policy = ::Role.create(role_id: 'rspec:policy:test/foo')
      %w[bar baz].each do |variable|
        ::Resource.create(
          resource_id: "rspec:variable:test/foo/#{variable}",
          owner_id: policy.id
        )
      end
    end
    context 'when secrets are loaded into a policy' do
      context 'without secret values' do
        it 'finds relevant variables' do
          expect(variable_repository.find_by_id_path(path: 'test/foo', account: 'rspec')).to eq(
            {
              'rspec:variable:test/foo/bar' => nil,
              'rspec:variable:test/foo/baz' => nil
            }
          )
        end
      end

      context 'with secret values' do
        before(:each) do
          %w[bar baz].each do |variable|
            ::Secret.create(
              resource_id: "rspec:variable:test/foo/#{variable}",
              value: variable
            )
          end
        end
        it 'finds relevant variables' do
          expect(variable_repository.find_by_id_path(path: 'test/foo', account: 'rspec')).to eq(
            {
              'rspec:variable:test/foo/bar' => 'bar',
              'rspec:variable:test/foo/baz' => 'baz'
            }
          )
        end
      end
    end

    context 'when variables are loaded into multiple policies' do
      before(:each) do
        policy = ::Role.create(role_id: 'rspec:policy:test/bar')
        %w[foo baz].each do |variable|
          ::Resource.create(
            resource_id: "rspec:variable:test/bar/#{variable}",
            owner_id: policy.id
          )
        end
      end
      it 'finds relevant variables' do
        expect(variable_repository.find_by_id_path(path: 'test/foo', account: 'rspec')).to eq(
          {
            'rspec:variable:test/foo/bar' => nil,
            'rspec:variable:test/foo/baz' => nil
          }
        )
      end
    end
  end
end
