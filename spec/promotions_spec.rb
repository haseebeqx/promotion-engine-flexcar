# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Promotion do
  let(:item) { Item.new(id: 1, name: 'Test Item', price: 10.0, sale_type: :quantity) }
  let(:weight_item) { Item.new(id: 2, name: 'Weight Item', price: 5.0, sale_type: :weight) }
  let(:cart_item) { CartItem.new(item: item, amount: 2) }
  let(:weight_cart_item) { CartItem.new(item: weight_item, amount: 150) }
  let(:start_time) { Time.now - 3600 }
  let(:end_time) { Time.now + 3600 }

  describe 'basic promotion functionality' do
    it 'all promotions inherit from Promotion base class' do
      flat_discount = FlatDiscount.new(id: 1, name: 'Test', discount_amount: 5.0, start_time: start_time)
      percentage_discount = PercentageDiscount.new(id: 2, name: 'Test', discount_percentage: 20, start_time: start_time)
      weight_threshold = WeightThreshold.new(id: 3, name: 'Test', threshold_weight: 100, discount_percentage: 30,
                                             start_time: start_time)
      buy_x_get_y = BuyXGetY.new(id: 4, name: 'Test', buy_quantity: 2, get_quantity: 1, start_time: start_time)

      expect(flat_discount).to be_a(Promotion)
      expect(percentage_discount).to be_a(Promotion)
      expect(weight_threshold).to be_a(Promotion)
      expect(buy_x_get_y).to be_a(Promotion)
    end

    it 'all promotions respond to calculate_discount method' do
      flat_discount = FlatDiscount.new(id: 1, name: 'Test', discount_amount: 5.0, start_time: start_time)
      percentage_discount = PercentageDiscount.new(id: 2, name: 'Test', discount_percentage: 20, start_time: start_time)
      weight_threshold = WeightThreshold.new(id: 3, name: 'Test', threshold_weight: 100, discount_percentage: 30,
                                             start_time: start_time)
      buy_x_get_y = BuyXGetY.new(id: 4, name: 'Test', buy_quantity: 2, get_quantity: 1, start_time: start_time)

      expect(flat_discount).to respond_to(:calculate_discount)
      expect(percentage_discount).to respond_to(:calculate_discount)
      expect(weight_threshold).to respond_to(:calculate_discount)
      expect(buy_x_get_y).to respond_to(:calculate_discount)
    end

    it 'all promotions respond to active? method' do
      flat_discount = FlatDiscount.new(id: 1, name: 'Test', discount_amount: 5.0, start_time: start_time)
      percentage_discount = PercentageDiscount.new(id: 2, name: 'Test', discount_percentage: 20, start_time: start_time)
      weight_threshold = WeightThreshold.new(id: 3, name: 'Test', threshold_weight: 100, discount_percentage: 30,
                                             start_time: start_time)
      buy_x_get_y = BuyXGetY.new(id: 4, name: 'Test', buy_quantity: 2, get_quantity: 1, start_time: start_time)

      expect(flat_discount).to respond_to(:active?)
      expect(percentage_discount).to respond_to(:active?)
      expect(weight_threshold).to respond_to(:active?)
      expect(buy_x_get_y).to respond_to(:active?)
    end
  end
end
