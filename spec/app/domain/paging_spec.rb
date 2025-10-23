# spec/domain/paging_spec.rb
require 'spec_helper'
# require_relative '../../app/domain/paging'

RSpec.describe(Paging) do
  describe '#initialize' do
    it 'sets limit and offset from input' do
      paging = Paging.new(limit: 10, offset: 5)
      expect(paging.limit).to eq(10)
      expect(paging.offset).to eq(5)
    end

    it 'defaults limit to MAX_LIMIT when no params given' do
      paging = Paging.new({})
      expect(paging.limit).to eq(Paging::MAX_LIMIT)
      expect(paging.offset).to eq(-1)
    end

    it 'defaults limit to DEFAULT_LIMIT_WHEN_OFFSET when only offset is given' do
      paging = Paging.new(offset: 2)
      expect(paging.limit).to eq(Paging::DEFAULT_LIMIT_WHEN_OFFSET)
      expect(paging.offset).to eq(2)
    end

    it 'raises error for negative offset' do
      expect { Paging.new(offset: -2) }.to raise_error(Validation::DomainValidationError)
    end

    it 'raises error for negative limit' do
      expect { Paging.new(limit: -1) }.to raise_error(Validation::DomainValidationError)
    end

    it 'raises error for limit above MAX_LIMIT' do
      expect { Paging.new(limit: Paging::MAX_LIMIT + 1) }.to raise_error(Validation::DomainValidationError)
    end
  end

  describe '#limit?' do
    it 'returns true if limit is set and > -1' do
      paging = Paging.new(limit: 5)
      expect(paging.limit?).to be(true)
    end

    it 'returns false if limit is -1' do
      paging = Paging.new({})
      expect(paging.limit?).to be(true)
    end
  end

  describe '#offset?' do
    it 'returns true if offset is set and > -1' do
      paging = Paging.new(offset: 0)
      expect(paging.offset?).to be(true)
    end

    it 'returns false if offset is -1' do
      paging = Paging.new({})
      expect(paging.offset?).to be(false)
    end
  end

  describe '#to_s' do
    it 'returns string representation' do
      paging = Paging.new(limit: 10, offset: 2)
      expect(paging.to_s).to eq("#<Paging limit=10 offset=2>")
    end
  end
end
