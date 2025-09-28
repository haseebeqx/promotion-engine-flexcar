# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PromotionSystem do
  let(:system) { PromotionSystem.new }
  let(:start_time) { Time.now - 3600 }
  let(:end_time) { Time.now + 3600 }

  before do
    # Create categories and brands
    system.create_category(id: 1, name: 'Electronics')
    system.create_category(id: 2, name: 'Food')
    system.create_brand(id: 1, name: 'Apple')
    system.create_brand(id: 2, name: 'Samsung')

    # Create items
    system.create_item(id: 1, name: 'iPhone', price: 999.99, sale_type: :quantity, category_ids: [1], brand_id: 1)
    system.create_item(id: 2, name: 'Samsung Phone', price: 799.99, sale_type: :quantity, category_ids: [1],
                       brand_id: 2)
    system.create_item(id: 3, name: 'Apples', price: 3.99, sale_type: :weight, category_ids: [2])
    system.create_item(id: 4, name: 'Bananas', price: 1.99, sale_type: :weight, category_ids: [2])
  end

  describe 'Cart with no promotions' do
    it 'calculates correct totals without promotions' do
      cart = system.create_cart

      cart.add_item(system.get_item(1), 1) # iPhone $999.99
      cart.add_item(system.get_item(3), 2) # 2kg Apples $7.98

      expect(cart.total_original_price).to eq(1007.97)
      expect(cart.total_discounted_price).to eq(1007.97)
      expect(cart.total_savings).to eq(0)
    end
  end

  describe 'Cart with flat discount promotion' do
    before do
      system.create_flat_discount(
        id: 1,
        name: '$100 off iPhone',
        discount_amount: 100,
        start_time: start_time,
        end_time: end_time,
        target_ids: [1]
      )
    end

    it 'applies flat discount correctly' do
      cart = system.create_cart
      cart.add_item(system.get_item(1), 1) # iPhone $999.99

      expect(cart.total_original_price).to eq(999.99)
      expect(cart.total_discounted_price).to eq(899.99)
      expect(cart.total_savings).to eq(100)
    end
  end

  describe 'Cart with percentage discount on category' do
    before do
      system.create_percentage_discount(
        id: 1,
        name: '20% off Electronics',
        discount_percentage: 20,
        start_time: start_time,
        end_time: end_time,
        target_type: :category,
        target_ids: [1]
      )
    end

    it 'applies percentage discount to category items' do
      cart = system.create_cart
      cart.add_item(system.get_item(1), 1) # iPhone $999.99
      cart.add_item(system.get_item(2), 1) # Samsung $799.99
      cart.add_item(system.get_item(3), 1) # Apples $3.99 (not electronics)

      expect(cart.total_original_price).to be_within(0.01).of(1803.97)
      # 20% off electronics: iPhone (200) + Samsung (160) = 360 discount
      expect(cart.total_discounted_price).to be_within(0.01).of(1443.97)
      expect(cart.total_savings).to be_within(0.01).of(360)
    end
  end

  describe 'Cart with weight threshold promotion' do
    before do
      system.create_weight_threshold(
        id: 1,
        name: 'Bulk fruit discount',
        threshold_weight: 5,
        discount_percentage: 25,
        start_time: start_time,
        end_time: end_time,
        target_type: :category,
        target_ids: [2]
      )
    end

    it 'applies weight threshold discount when threshold is met' do
      cart = system.create_cart
      cart.add_item(system.get_item(3), 6) # 6kg Apples $23.94

      expect(cart.total_original_price).to be_within(0.01).of(23.94)
      expect(cart.total_discounted_price).to be_within(0.01).of(17.955) # 25% off
      expect(cart.total_savings).to be_within(0.01).of(5.985)
    end

    it 'does not apply discount when threshold is not met' do
      cart = system.create_cart
      cart.add_item(system.get_item(3), 2) # 2kg Apples $7.98

      expect(cart.total_original_price).to eq(7.98)
      expect(cart.total_discounted_price).to eq(7.98)
      expect(cart.total_savings).to eq(0)
    end
  end

  describe 'Cart with Buy X Get Y promotion' do
    before do
      system.create_buy_x_get_y(
        id: 1,
        name: 'Buy 2 Get 1 Free Electronics',
        buy_quantity: 2,
        get_quantity: 1,
        get_discount_percentage: 100,
        start_time: start_time,
        end_time: end_time,
        target_type: :category,
        target_ids: [1]
      )
    end

    it 'applies buy x get y discount correctly' do
      cart = system.create_cart
      # Add 3 phones - should get cheapest one free
      cart.add_item(system.get_item(1), 1) # iPhone $999.99
      cart.add_item(system.get_item(2), 2) # 2x Samsung $1599.98

      expect(cart.total_original_price).to be_within(0.01).of(2599.97)
      # Should get one Samsung phone free (cheapest individual item)
      expect(cart.total_discounted_price).to be_within(0.01).of(1799.98)
      expect(cart.total_savings).to be_within(0.01).of(799.99)
    end
  end

  describe 'Multiple promotions - best one wins' do
    before do
      system.create_flat_discount(
        id: 1,
        name: '$50 off iPhone',
        discount_amount: 50,
        start_time: start_time,
        end_time: end_time,
        target_ids: [1]
      )

      system.create_percentage_discount(
        id: 2,
        name: '10% off iPhone',
        discount_percentage: 10,
        start_time: start_time,
        end_time: end_time,
        target_ids: [1]
      )
    end

    it 'applies the better promotion' do
      cart = system.create_cart
      cart.add_item(system.get_item(1), 1) # iPhone $999.99

      expect(cart.total_original_price).to be_within(0.01).of(999.99)
      # 10% ($100) is better than $50 flat discount
      expect(cart.total_discounted_price).to be_within(0.01).of(899.99)
      expect(cart.total_savings).to be_within(0.01).of(100)
    end
  end
end
