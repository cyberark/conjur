# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Presenter::PolicyFactories::Show) do
  describe '.present' do
    subject { Presenter::PolicyFactories::Show.new(factory: factory) }
    context 'when factory is composed of string keys' do
      let(:factory) do
        DB::Repository::DataObjects::PolicyFactory.new(
          schema: {
            'title' => 'foo-bar',
            'description' => 'some factory',
            'properties' => {
              'id' => {
                'description' => 'Group ID',
                'type' => 'string'
              },
              'branch' => {
                'description' => 'Policy branch to load this group into',
                'type' => 'string'
              },
              'annotations' => {
                'description' => 'Additional annotations to add to the group',
                'type' => 'object'
              }
            },
            'required' => %w[id branch]
          },
          version: 'v1'
        )
      end

      it 'returns the expected hash' do
        expect(subject.present).to include(
          {
            title: 'foo-bar',
            version: 'v1',
            description: 'some factory',
            properties: {
              'annotations' => {
                'description' => 'Additional annotations to add to the group',
                'type' => 'object'
              },
              'branch' => {
                'description' => 'Policy branch to load this group into',
                'type' => 'string'
              },
              'id' => {
                'description' => 'Group ID',
                'type' => 'string'
              }
            },
            required: %w[id branch]
          }
        )
      end
    end
  end
end
