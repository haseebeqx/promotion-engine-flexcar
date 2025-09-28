# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WeightThreshold do
  let(:weight_item) { Item.new(id: 2, name: 'Weight Item', price: 5.0, sale_type: :weight) }
  let(:quantity_item) { Item.new(id: 1, name: 'Quantity Item', price: 10.0, sale_type: :quantity) }
  let(:weight_cart_item) { CartItem.new(item: weight_item, amount: 150) }
  let(:quantity_cart_item) { CartItem.new(item: quantity_item, amount: 2) }
  let(:start_time) { Time.now - 3600 }
  let(:end_time) { Time.now + 3600 }

  describe 'initialization' do
    it 'creates promotion with valid parameters' do
      promotion = WeightThreshold.new(
        id: 1,
        name: 'Weight discount',
        threshold_weight: 100,
        discount_percentage: 30,
        start_time: start_time,
        end_time: end_time,
        target_ids: [weight_item.id]
      )

      expect(promotion.threshold_weight).to eq(100)
      expect(promotion.discount_percentage).to eq(30)
      expect(promotion.name).to eq('Weight discount')
      expect(promotion.id).to eq(1)
    end

    it 'validates threshold weight is positive' do
      expect do
        WeightThreshold.new(
          id: 1,
          name: 'Invalid',
          threshold_weight: -100,
          discount_percentage: 30,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Threshold weight must be a positive number/)
    end

    it 'validates threshold weight is numeric' do
      expect do
        WeightThreshold.new(
          id: 1,
          name: 'Invalid',
          threshold_weight: 'not_a_number',
          discount_percentage: 30,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Threshold weight must be a positive number/)
    end

    it 'validates discount percentage is between 0 and 99' do
      expect do
        WeightThreshold.new(
          id: 1,
          name: 'Invalid',
          threshold_weight: 100,
          discount_percentage: 100,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Discount percentage must be between 0 and 99/)
    end

    it 'validates discount percentage is positive' do
      expect do
        WeightThreshold.new(
          id: 1,
          name: 'Invalid',
          threshold_weight: 100,
          discount_percentage: -10,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /Discount percentage must be between 0 and 99/)
    end
  end

  describe '#can_apply_to?' do
    let(:promotion) do
      WeightThreshold.new(
        id: 1,
        name: 'Weight discount',
        threshold_weight: 100,
        discount_percentage: 30,
        start_time: start_time,
        target_ids: [weight_item.id]
      )
    end

    it 'returns true for applicable weight-based items' do
      expect(promotion.can_apply_to?(weight_cart_item)).to be true
    end

    it 'returns false for quantity-based items' do
      expect(promotion.can_apply_to?(quantity_cart_item)).to be false
    end

    it 'returns false for non-target items' do
      other_weight_item = Item.new(id: 3, name: 'Other Weight Item', price: 8.0, sale_type: :weight)
      other_cart_item = CartItem.new(item: other_weight_item, amount: 200)
      expect(promotion.can_apply_to?(other_cart_item)).to be false
    end
  end

  describe '#calculate_discount' do
    let(:promotion) do
      WeightThreshold.new(
        id: 1,
        name: 'Weight discount',
        threshold_weight: 100,
        discount_percentage: 30,
        start_time: start_time,
        end_time: end_time,
        target_ids: [weight_item.id]
      )
    end

    it 'applies discount when threshold is met' do
      discount = promotion.calculate_discount(weight_cart_item)
      expect(discount).to eq(225.0) # 30% of 750.0
    end

    it 'does not apply discount when threshold is not met' do
      small_cart_item = CartItem.new(item: weight_item, amount: 50)
      discount = promotion.calculate_discount(small_cart_item)
      expect(discount).to eq(0)
    end

    it 'returns 0 for quantity-based items' do
      discount = promotion.calculate_discount(quantity_cart_item)
      expect(discount).to eq(0)
    end

    it 'returns 0 for non-applicable items' do
      non_target_item = Item.new(id: 3, name: 'Other Item', price: 8.0, sale_type: :weight)
      non_target_cart_item = CartItem.new(item: non_target_item, amount: 200)

      discount = promotion.calculate_discount(non_target_cart_item)
      expect(discount).to eq(0)
    end

    it 'returns 0 for inactive promotions' do
      inactive_promotion = WeightThreshold.new(
        id: 3,
        name: 'Expired',
        threshold_weight: 100,
        discount_percentage: 30,
        start_time: Time.now - 7200,
        end_time: Time.now - 3600,
        target_ids: [weight_item.id]
      )

      discount = inactive_promotion.calculate_discount(weight_cart_item)
      expect(discount).to eq(0)
    end
  end

  describe '#to_s' do
    it 'displays promotion correctly' do
      promotion = WeightThreshold.new(
        id: 1,
        name: 'Bulk Discount',
        threshold_weight: 200,
        discount_percentage: 25,
        start_time: start_time
      )

      expect(promotion.to_s).to eq('Bulk Discount - 25% off when buying 200+ grams')
    end
  end
end
