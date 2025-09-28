# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FlatDiscount do
  let(:item) { Item.new(id: 1, name: 'Test Item', price: 10.0, sale_type: :quantity) }
  let(:cart_item) { CartItem.new(item: item, amount: 2) }
  let(:start_time) { Time.now - 3600 }
  let(:end_time) { Time.now + 3600 }

  describe 'initialization' do
    it 'creates promotion with valid parameters' do
      promotion = FlatDiscount.new(
        id: 1,
        name: 'Flat $5 off',
        discount_amount: 5.0,
        start_time: start_time,
        end_time: end_time,
        target_ids: [item.id]
      )

      expect(promotion.discount_amount).to eq(5.0)
      expect(promotion.name).to eq('Flat $5 off')
      expect(promotion.id).to eq(1)
    end

    it 'validates discount amount is positive' do
      expect do
        FlatDiscount.new(
          id: 1,
          name: 'Invalid',
          discount_amount: -5.0,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Discount amount must be a positive number/)
    end

    it 'validates discount amount is numeric' do
      expect do
        FlatDiscount.new(
          id: 1,
          name: 'Invalid',
          discount_amount: 'not_a_number',
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Discount amount must be a positive number/)
    end
  end

  describe '#calculate_discount' do
    let(:promotion) do
      FlatDiscount.new(
        id: 1,
        name: 'Flat $5 off',
        discount_amount: 5.0,
        start_time: start_time,
        end_time: end_time,
        target_ids: [item.id]
      )
    end

    it 'applies flat discount correctly' do
      discount = promotion.calculate_discount(cart_item)
      expect(discount).to eq(5.0)
    end

    it 'does not exceed item price' do
      expensive_promotion = FlatDiscount.new(
        id: 2,
        name: 'Flat $50 off',
        discount_amount: 50.0,
        start_time: start_time,
        target_ids: [item.id]
      )

      discount = expensive_promotion.calculate_discount(cart_item)
      expect(discount).to eq(cart_item.original_price)
    end

    it 'returns 0 for non-applicable items' do
      non_target_item = Item.new(id: 2, name: 'Other Item', price: 15.0, sale_type: :quantity)
      non_target_cart_item = CartItem.new(item: non_target_item, amount: 1)

      discount = promotion.calculate_discount(non_target_cart_item)
      expect(discount).to eq(0)
    end

    it 'returns 0 for inactive promotions' do
      inactive_promotion = FlatDiscount.new(
        id: 3,
        name: 'Expired',
        discount_amount: 5.0,
        start_time: Time.now - 7200,
        end_time: Time.now - 3600,
        target_ids: [item.id]
      )

      discount = inactive_promotion.calculate_discount(cart_item)
      expect(discount).to eq(0)
    end
  end

  describe '#to_s' do
    it 'displays promotion correctly' do
      promotion = FlatDiscount.new(
        id: 1,
        name: 'Special Deal',
        discount_amount: 10.0,
        start_time: start_time
      )

      expect(promotion.to_s).to eq('Special Deal - $10.0 off')
    end
  end
end
