# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Presenter::PolicyFactories::Index) do
  describe '.present' do
    subject do
      Presenter::PolicyFactories::Index.new(
        factories: [
          DB::Repository::DataObjects::PolicyFactory.new(
            name: 'foo1',
            classification: 'foo',
            version: 'v1',
            description: 'This is foo'
          ),
          DB::Repository::DataObjects::PolicyFactory.new(
            name: 'bar1',
            classification: 'foo',
            version: 'v1'
          )
        ]
      )
    end

    it 'returns the expected hash' do
      expect(subject.present).to include(
        {
          "foo" => [
            {
              name: 'bar1',
              namespace: 'foo',
              'full-name': 'foo/bar1',
              'current-version': 'v1',
              description: ''
            }, {
              name: 'foo1',
              namespace: 'foo',
              'full-name': 'foo/foo1',
              'current-version': 'v1',
              description: 'This is foo'
            }
          ]
        }
      )
    end
  end
end
