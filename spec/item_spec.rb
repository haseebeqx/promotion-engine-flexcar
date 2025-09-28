# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Item do
  let(:category) { Category.new(id: 1, name: 'Electronics') }
  let(:brand) { Brand.new(id: 1, name: 'Apple') }

  describe '#initialize' do
    it 'creates an item with required attributes' do
      item = Item.new(
        id: 1,
        name: 'iPhone',
        price: 999.99,
        sale_type: :quantity
      )

      expect(item.id).to eq(1)
      expect(item.name).to eq('iPhone')
      expect(item.price).to eq(999.99)
      expect(item.sale_type).to eq(:quantity)
      expect(item.categories).to be_empty
      expect(item.brand).to be_nil
    end

    it 'creates an item with categories and brand' do
      item = Item.new(
        id: 1,
        name: 'iPhone',
        price: 999.99,
        sale_type: :quantity,
        categories: [category],
        brand: brand
      )

      expect(item.categories).to eq([category])
      expect(item.brand).to eq(brand)
    end

    it 'raises error for invalid sale type' do
      expect do
        Item.new(
          id: 1,
          name: 'iPhone',
          price: 999.99,
          sale_type: :invalid
        )
      end.to raise_error(ArgumentError, /Invalid sale type/)
    end
  end

  describe '#sold_by_weight?' do
    it 'returns true for weight-based items' do
      item = Item.new(id: 1, name: 'Apples', price: 2.99, sale_type: :weight)
      expect(item.sold_by_weight?).to be true
    end

    it 'returns false for quantity-based items' do
      item = Item.new(id: 1, name: 'iPhone', price: 999.99, sale_type: :quantity)
      expect(item.sold_by_weight?).to be false
    end
  end

  describe '#sold_by_quantity?' do
    it 'returns true for quantity-based items' do
      item = Item.new(id: 1, name: 'iPhone', price: 999.99, sale_type: :quantity)
      expect(item.sold_by_quantity?).to be true
    end

    it 'returns false for weight-based items' do
      item = Item.new(id: 1, name: 'Apples', price: 2.99, sale_type: :weight)
      expect(item.sold_by_quantity?).to be false
    end
  end
end
