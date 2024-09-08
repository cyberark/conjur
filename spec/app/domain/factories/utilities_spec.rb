# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Factories::Utilities) do
  subject { Factories::Utilities }
  describe '.filter_input' do
    context 'when input is valid' do
      it 'filters out invalid characters' do
        expect(subject.filter_input('foo')).to eq('foo')
        expect(subject.filter_input('foo-bar')).to eq('foo-bar')
        expect(subject.filter_input('foo_bar')).to eq('foo_bar')
        expect(subject.filter_input('foo/bar')).to eq('foo/bar')
        expect(subject.filter_input('foo123')).to eq('foo123')
        expect(subject.filter_input('123')).to eq('123')
        expect(subject.filter_input('foo,bar')).to eq('foo,bar')
      end
    end
    context 'when input is invalid' do
      it 'filters out invalid characters' do
        expect(subject.filter_input('foo!')).to eq('foo')
        expect(subject.filter_input('foo@')).to eq('foo')
        expect(subject.filter_input('foo#')).to eq('foo')
        expect(subject.filter_input('foo$')).to eq('foo')
        expect(subject.filter_input('foo%')).to eq('foo')
        expect(subject.filter_input('foo^')).to eq('foo')
        expect(subject.filter_input('foo&')).to eq('foo')
        expect(subject.filter_input('foo*')).to eq('foo')
        expect(subject.filter_input('foo(')).to eq('foo')
        expect(subject.filter_input('foo)')).to eq('foo')
        expect(subject.filter_input('foo\\')).to eq('foo')
        expect(subject.filter_input('foo|')).to eq('foo')
        expect(subject.filter_input('foo`')).to eq('foo')
        expect(subject.filter_input('foo~')).to eq('foo')
        expect(subject.filter_input('foo{')).to eq('foo')
        expect(subject.filter_input('foo}')).to eq('foo')
        expect(subject.filter_input('foo[')).to eq('foo')
        expect(subject.filter_input('foo]')).to eq('foo')
        expect(subject.filter_input('foo:')).to eq('foo')
        expect(subject.filter_input('foo;')).to eq('foo')
        expect(subject.filter_input('foo<')).to eq('foo')
        expect(subject.filter_input('foo>')).to eq('foo')
      end
    end
  end
end
