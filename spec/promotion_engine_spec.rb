# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PromotionEngine do
  let(:category1) { Category.new(id: 1, name: 'Electronics') }
  let(:category2) { Category.new(id: 2, name: 'Books') }
  let(:item1) { Item.new(id: 1, name: 'Widget', price: 50.0, sale_type: :quantity, categories: [category1]) }
  let(:item2) { Item.new(id: 2, name: 'Gadget', price: 30.0, sale_type: :quantity, categories: [category1]) }
  let(:item3) { Item.new(id: 3, name: 'Book', price: 20.0, sale_type: :quantity, categories: [category2]) }
  let(:cart) { Cart.new }
  let(:engine) { PromotionEngine.new }

  describe 'optimal promotion selection' do
    context 'single item with competing promotions' do
      before do
        cart.add_item(item1, 1) # 1 item at $50

        # 60% off individual promotion
        engine.add_promotion(PercentageDiscount.new(
                               id: 1, name: '60% off Item 1', discount_percentage: 60,
                               start_time: Time.now - 3600, target_type: :item, target_ids: [item1.id]
                             ))

        # Buy 1 get 1 free category promotion
        engine.add_promotion(BuyXGetY.new(
                               id: 2, name: 'Buy 1 Get 1 Free', buy_quantity: 1, get_quantity: 1,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category1.id]
                             ))
      end

      it 'chooses 60% off over buy 1 get 1 free for single item' do
        # With 1 item:
        # - 60% off: $50 * 0.6 = $30 discount, final cost = $20
        # - Buy 1 get 1 free: requires 2 items minimum, so no discount, final cost = $50

        engine.apply_best_promotions(cart)

        cart_item = cart.items.first
        expect(cart_item.applied_promotion.name).to eq('60% off Item 1')
        expect(cart_item.savings).to eq(30.0) # $50 * 0.6 = $30 savings
        expect(cart_item.discounted_price).to eq(20.0) # Final cost: $20
      end
    end

    context 'two items where individual promotion remains better' do
      before do
        cart.add_item(item1, 2) # 2 items at $50 each = $100 total

        # 60% off individual promotion
        engine.add_promotion(PercentageDiscount.new(
                               id: 1, name: '60% off Item 1', discount_percentage: 60,
                               start_time: Time.now - 3600, target_type: :item, target_ids: [item1.id]
                             ))

        # Buy 1 get 1 free category promotion
        engine.add_promotion(BuyXGetY.new(
                               id: 2, name: 'Buy 1 Get 1 Free', buy_quantity: 1, get_quantity: 1,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category1.id]
                             ))
      end

      it 'chooses individual promotion when it provides better total savings' do
        # With 2 items (as one CartItem with amount=2):
        # - 60% off: $100 * 0.6 = $60 discount, final cost = $40
        # - Buy 1 get 1 free: $50 discount (1 item free), final cost = $50
        # So 60% off is still better

        engine.apply_best_promotions(cart)

        cart_item = cart.items.first
        expect(cart_item.applied_promotion.name).to eq('60% off Item 1')
        expect(cart_item.savings).to eq(60.0) # $100 * 0.6
        expect(cart_item.discounted_price).to eq(40.0) # $100 - $60

        total_savings = cart.items.sum(&:savings)
        expect(total_savings).to eq(60.0)
      end
    end

    context 'when buy x get y becomes optimal with weaker individual promotion' do
      before do
        cart.add_item(item1, 2) # 2 items at $50 each = $100 total

        # Weak individual promotion
        engine.add_promotion(PercentageDiscount.new(
                               id: 1, name: '20% off Item 1', discount_percentage: 20,
                               start_time: Time.now - 3600, target_type: :item, target_ids: [item1.id]
                             ))

        # Strong category promotion
        engine.add_promotion(BuyXGetY.new(
                               id: 2, name: 'Buy 1 Get 1 Free', buy_quantity: 1, get_quantity: 1,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category1.id]
                             ))
      end

      it 'chooses buy x get y when it provides better savings' do
        # With 2 items:
        # - 20% off each: 2 * ($50 * 0.2) = $20 discount, final cost = $80
        # - Buy 1 get 1 free: $50 discount (1 item free), final cost = $50
        # So buy 1 get 1 free is better

        engine.apply_best_promotions(cart)

        total_savings = cart.items.sum(&:savings)
        expect(total_savings).to eq(50.0)

        # Should have buy x get y promotion applied
        buy_x_get_y_applied = cart.items.any? { |ci| ci.applied_promotion&.name == 'Buy 1 Get 1 Free' }
        expect(buy_x_get_y_applied).to be true
      end
    end

    context 'multiple items with different optimal strategies' do
      before do
        cart.add_item(item1, 2) # 2 items at $50 each = $100 total
        cart.add_item(item2, 1) # 1 item at $30 = $30 total
        # Total cart value: $130

        # Individual promotions
        engine.add_promotion(PercentageDiscount.new(
                               id: 1, name: '40% off Item 1', discount_percentage: 40,
                               start_time: Time.now - 3600, target_type: :item, target_ids: [item1.id]
                             ))

        engine.add_promotion(PercentageDiscount.new(
                               id: 2, name: '50% off Item 2', discount_percentage: 50,
                               start_time: Time.now - 3600, target_type: :item, target_ids: [item2.id]
                             ))

        # Category promotion
        engine.add_promotion(BuyXGetY.new(
                               id: 3, name: 'Buy 2 Get 1 Free', buy_quantity: 2, get_quantity: 1,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category1.id]
                             ))
      end

      it 'chooses individual promotions when they provide better total savings' do
        # Individual promotions: 2*($50*0.4) + 1*($30*0.5) = $40 + $15 = $55 savings
        # Buy 2 get 1 free: $30 savings (cheapest item free)
        # Individual promotions are better: $55 > $30

        engine.apply_best_promotions(cart)

        item1_items = cart.items.select { |ci| ci.item.id == item1.id }
        item2_items = cart.items.select { |ci| ci.item.id == item2.id }

        # All item1 instances should have 40% off
        item1_items.each do |cart_item|
          expect(cart_item.applied_promotion.name).to eq('40% off Item 1')
          expect(cart_item.savings).to eq(40.0) # 2 items * ($50 * 0.4) = $40 total
        end

        # Item2 should have 50% off
        item2_items.each do |cart_item|
          expect(cart_item.applied_promotion.name).to eq('50% off Item 2')
          expect(cart_item.savings).to eq(15.0) # $30 * 0.5
        end

        total_savings = cart.items.sum(&:savings)
        expect(total_savings).to eq(55.0)
      end
    end

    context 'three items where buy x get y becomes optimal' do
      before do
        cart.add_item(item1, 3) # 3 items at $50 each = $150 total

        # Weak individual promotion
        engine.add_promotion(PercentageDiscount.new(
                               id: 1, name: '10% off Item 1', discount_percentage: 10,
                               start_time: Time.now - 3600, target_type: :item, target_ids: [item1.id]
                             ))

        # Strong category promotion
        engine.add_promotion(BuyXGetY.new(
                               id: 2, name: 'Buy 2 Get 1 Free', buy_quantity: 2, get_quantity: 1,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category1.id]
                             ))
      end

      it 'chooses buy x get y when it provides better savings' do
        # Individual promotion: 3 * ($50 * 0.1) = $15 savings
        # Buy 2 get 1 free: $50 savings (1 item free)
        # Buy x get y is better: $50 > $15

        engine.apply_best_promotions(cart)

        total_savings = cart.items.sum(&:savings)
        expect(total_savings).to eq(50.0)

        # At least one item should have the buy x get y promotion
        buy_x_get_y_applied = cart.items.any? { |ci| ci.applied_promotion&.name == 'Buy 2 Get 1 Free' }
        expect(buy_x_get_y_applied).to be true
      end
    end

    context 'mixed categories with complex scenarios' do
      before do
        cart.add_item(item1, 2) # 2 electronics at $50 each
        cart.add_item(item3, 3) # 3 books at $20 each

        # Electronics promotions
        engine.add_promotion(PercentageDiscount.new(
                               id: 1, name: '30% off Electronics', discount_percentage: 30,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category1.id]
                             ))

        engine.add_promotion(BuyXGetY.new(
                               id: 2, name: 'Electronics: Buy 1 Get 1 Free', buy_quantity: 1, get_quantity: 1,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category1.id]
                             ))

        # Books promotions
        engine.add_promotion(PercentageDiscount.new(
                               id: 3, name: '25% off Books', discount_percentage: 25,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category2.id]
                             ))

        engine.add_promotion(BuyXGetY.new(
                               id: 4, name: 'Books: Buy 2 Get 1 Free', buy_quantity: 2, get_quantity: 1,
                               start_time: Time.now - 3600, target_type: :category, target_ids: [category2.id]
                             ))
      end

      it 'optimally combines promotions across categories' do
        # Electronics: 30% off = 2*($50*0.3) = $30 vs Buy 1 Get 1 Free = $50
        # Books: 25% off = 3*($20*0.25) = $15 vs Buy 2 Get 1 Free = $20
        # Optimal: Electronics Buy 1 Get 1 Free ($50) + Books Buy 2 Get 1 Free ($20) = $70 total

        engine.apply_best_promotions(cart)

        total_savings = cart.items.sum(&:savings)
        expect(total_savings).to eq(70.0)
      end
    end

    context 'no promotions available' do
      before do
        cart.add_item(item1, 1)
      end

      it 'applies no promotions when none are available' do
        engine.apply_best_promotions(cart)

        cart.items.each do |cart_item|
          expect(cart_item.has_promotion?).to be false
          expect(cart_item.savings).to eq(0)
          expect(cart_item.discounted_price).to eq(cart_item.original_price)
        end
      end
    end
  end
end
