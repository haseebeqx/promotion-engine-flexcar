# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PercentageDiscount do
  let(:item) { Item.new(id: 1, name: 'Test Item', price: 10.0, sale_type: :quantity) }
  let(:cart_item) { CartItem.new(item: item, amount: 2) }
  let(:start_time) { Time.now - 3600 }
  let(:end_time) { Time.now + 3600 }

  describe 'initialization' do
    it 'creates promotion with valid parameters' do
      promotion = PercentageDiscount.new(
        id: 1,
        name: '20% off',
        discount_percentage: 20,
        start_time: start_time,
        end_time: end_time,
        target_ids: [item.id]
      )

      expect(promotion.discount_percentage).to eq(20)
      expect(promotion.name).to eq('20% off')
      expect(promotion.id).to eq(1)
    end

    it 'validates discount percentage is positive' do
      expect do
        PercentageDiscount.new(
          id: 1,
          name: 'Invalid',
          discount_percentage: -10,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Discount percentage must be between 0 and 100/)
    end

    it 'validates discount percentage is not greater than 100' do
      expect do
        PercentageDiscount.new(
          id: 1,
          name: 'Invalid',
          discount_percentage: 150,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Discount percentage must be between 0 and 100/)
    end

    it 'validates discount percentage is numeric' do
      expect do
        PercentageDiscount.new(
          id: 1,
          name: 'Invalid',
          discount_percentage: 'not_a_number',
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Discount percentage must be between 0 and 100/)
    end
  end

  describe '#calculate_discount' do
    let(:promotion) do
      PercentageDiscount.new(
        id: 1,
        name: '20% off',
        discount_percentage: 20,
        start_time: start_time,
        end_time: end_time,
        target_ids: [item.id]
      )
    end

    it 'applies percentage discount correctly' do
      discount = promotion.calculate_discount(cart_item)
      expect(discount).to eq(4.0) # 20% of 20.0
    end

    it 'handles different percentages' do
      fifty_percent_promotion = PercentageDiscount.new(
        id: 2,
        name: '50% off',
        discount_percentage: 50,
        start_time: start_time,
        target_ids: [item.id]
      )

      discount = fifty_percent_promotion.calculate_discount(cart_item)
      expect(discount).to eq(10.0) # 50% of 20.0
    end

    it 'returns 0 for non-applicable items' do
      non_target_item = Item.new(id: 2, name: 'Other Item', price: 15.0, sale_type: :quantity)
      non_target_cart_item = CartItem.new(item: non_target_item, amount: 1)

      discount = promotion.calculate_discount(non_target_cart_item)
      expect(discount).to eq(0)
    end

    it 'returns 0 for inactive promotions' do
      inactive_promotion = PercentageDiscount.new(
        id: 3,
        name: 'Expired',
        discount_percentage: 20,
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
      promotion = PercentageDiscount.new(
        id: 1,
        name: 'Special Deal',
        discount_percentage: 25,
        start_time: start_time
      )

      expect(promotion.to_s).to eq('Special Deal - 25% off')
    end
  end
end
