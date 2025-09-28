# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Brand do
  describe '#initialize' do
    it 'creates a brand with id and name' do
      brand = Brand.new(id: 1, name: 'Nike')

      expect(brand.id).to eq(1)
      expect(brand.name).to eq('Nike')
    end
  end

  describe '#==' do
    it 'returns true for brands with same id' do
      brand1 = Brand.new(id: 1, name: 'Nike')
      brand2 = Brand.new(id: 1, name: 'Adidas')

      expect(brand1).to eq(brand2)
    end

    it 'returns false for brands with different ids' do
      brand1 = Brand.new(id: 1, name: 'Nike')
      brand2 = Brand.new(id: 2, name: 'Nike')

      expect(brand1).not_to eq(brand2)
    end
  end

  describe '#to_s' do
    it 'returns the brand name' do
      brand = Brand.new(id: 1, name: 'Nike')

      expect(brand.to_s).to eq('Nike')
    end
  end
end
