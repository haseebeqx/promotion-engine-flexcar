# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuyXGetY do
  let(:item1) { Item.new(id: 1, name: 'Phone', price: 100.0, sale_type: :quantity) }
  let(:item2) { Item.new(id: 2, name: 'Case', price: 20.0, sale_type: :quantity) }
  let(:item3) { Item.new(id: 3, name: 'Charger', price: 50.0, sale_type: :quantity) }
  let(:weight_item) { Item.new(id: 4, name: 'Apples', price: 5.0, sale_type: :weight) }
  let(:start_time) { Time.now - 3600 }
  let(:end_time) { Time.now + 3600 }

  describe 'initialization' do
    it 'creates promotion with valid parameters' do
      promotion = BuyXGetY.new(
        id: 1,
        name: 'Test Promotion',
        buy_quantity: 2,
        get_quantity: 3,
        start_time: start_time
      )

      expect(promotion.buy_quantity).to eq(2)
      expect(promotion.get_quantity).to eq(3)
      expect(promotion.get_discount_percentage).to eq(100)
    end

    it 'accepts custom discount percentage' do
      promotion = BuyXGetY.new(
        id: 1,
        name: 'Test Promotion',
        buy_quantity: 2,
        get_quantity: 1,
        get_discount_percentage: 50,
        start_time: start_time
      )

      expect(promotion.get_discount_percentage).to eq(50)
    end

    it 'validates buy_quantity is positive' do
      expect do
        BuyXGetY.new(
          id: 1,
          name: 'Test',
          buy_quantity: 0,
          get_quantity: 1,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /buy_quantity must be a positive integer/)
    end

    it 'validates get_quantity is positive' do
      expect do
        BuyXGetY.new(
          id: 1,
          name: 'Test',
          buy_quantity: 1,
          get_quantity: -1,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /get_quantity must be a positive integer/)
    end

    it 'validates discount percentage is between 0 and 100' do
      expect do
        BuyXGetY.new(
          id: 1,
          name: 'Test',
          buy_quantity: 1,
          get_quantity: 1,
          get_discount_percentage: 150,
          start_time: start_time
        )
      end.to raise_error(ArgumentError, /get_discount_percentage must be between 0 and 100/)
    end
  end

  describe '#can_apply_to?' do
    let(:promotion) do
      BuyXGetY.new(
        id: 1,
        name: 'Test',
        buy_quantity: 2,
        get_quantity: 1,
        start_time: start_time,
        target_ids: [1, 2]
      )
    end

    it 'returns true for applicable quantity-based items' do
      cart_item = CartItem.new(item: item1, amount: 3)
      expect(promotion.can_apply_to?(cart_item)).to be true
    end

    it 'returns false for weight-based items' do
      cart_item = CartItem.new(item: weight_item, amount: 100)
      expect(promotion.can_apply_to?(cart_item)).to be false
    end

    it 'returns false for non-target items' do
      cart_item = CartItem.new(item: item3, amount: 3)
      expect(promotion.can_apply_to?(cart_item)).to be false
    end
  end

  describe '#calculate_discount' do
    context 'when get_quantity > buy_quantity (e.g., Buy 2 Get 3)' do
      let(:promotion) do
        BuyXGetY.new(
          id: 1,
          name: 'Buy 2 Get 3',
          buy_quantity: 2,
          get_quantity: 3,
          start_time: start_time,
          target_ids: [1]
        )
      end

      it 'requires minimum items to qualify' do
        cart_items = [CartItem.new(item: item1, amount: 2)]
        expect(promotion.calculate_discount(cart_items)).to eq(0)
      end

      it 'gives discount when customer has enough items' do
        cart_items = [CartItem.new(item: item1, amount: 3)]
        # 3 items: pay for 2, get 1 free (partial set)
        expect(promotion.calculate_discount(cart_items)).to eq(100.0)
      end

      it 'handles complete promotion sets' do
        cart_items = [CartItem.new(item: item1, amount: 5)]
        # 5 items = 1 complete set (2 paid + 3 free) = 3 free items
        expect(promotion.calculate_discount(cart_items)).to eq(300.0)
      end

      it 'handles multiple complete sets' do
        cart_items = [CartItem.new(item: item1, amount: 10)]
        # 10 items = 2 complete sets (4 paid + 6 free) = 6 free items
        expect(promotion.calculate_discount(cart_items)).to eq(600.0)
      end
    end

    context 'when get_quantity < buy_quantity (e.g., Buy 5 Get 2)' do
      let(:promotion) do
        BuyXGetY.new(
          id: 1,
          name: 'Buy 5 Get 2',
          buy_quantity: 5,
          get_quantity: 2,
          start_time: start_time,
          target_ids: [1]
        )
      end

      it 'requires minimum items to qualify' do
        cart_items = [CartItem.new(item: item1, amount: 5)]
        expect(promotion.calculate_discount(cart_items)).to eq(0)
      end

      it 'gives discount when customer has enough items' do
        cart_items = [CartItem.new(item: item1, amount: 6)]
        # 6 items: pay for 5, get 1 free (partial set)
        expect(promotion.calculate_discount(cart_items)).to eq(100.0)
      end

      it 'handles complete promotion sets' do
        cart_items = [CartItem.new(item: item1, amount: 7)]
        # 7 items = 1 complete set (5 paid + 2 free) = 2 free items
        expect(promotion.calculate_discount(cart_items)).to eq(200.0)
      end

      it 'handles partial second set' do
        cart_items = [CartItem.new(item: item1, amount: 13)]
        # 13 items = 1 complete set (7 items) + 6 remaining items
        # Remaining: pay for 5, get 1 free = total 3 free items
        expect(promotion.calculate_discount(cart_items)).to eq(300.0)
      end
    end

    context 'when get_quantity = buy_quantity (e.g., Buy 3 Get 3)' do
      let(:promotion) do
        BuyXGetY.new(
          id: 1,
          name: 'Buy 3 Get 3',
          buy_quantity: 3,
          get_quantity: 3,
          start_time: start_time,
          target_ids: [1]
        )
      end

      it 'gives 50% discount on complete sets' do
        cart_items = [CartItem.new(item: item1, amount: 6)]
        # 6 items = 1 complete set (3 paid + 3 free) = 3 free items
        expect(promotion.calculate_discount(cart_items)).to eq(300.0)
      end

      it 'handles partial sets correctly' do
        cart_items = [CartItem.new(item: item1, amount: 8)]
        # 8 items = 1 complete set (6 items) + 2 remaining (no discount)
        expect(promotion.calculate_discount(cart_items)).to eq(300.0)
      end
    end

    context 'with mixed item prices' do
      let(:promotion) do
        BuyXGetY.new(
          id: 1,
          name: 'Buy 2 Get 1',
          buy_quantity: 2,
          get_quantity: 1,
          start_time: start_time,
          target_ids: [1, 2, 3]
        )
      end

      it 'discounts cheapest items first' do
        cart_items = [
          CartItem.new(item: item1, amount: 1), # $100
          CartItem.new(item: item2, amount: 1), # $20
          CartItem.new(item: item3, amount: 1)  # $50
        ]
        # 3 items = 1 complete set, cheapest item ($20) should be free
        expect(promotion.calculate_discount(cart_items)).to eq(20.0)
      end

      it 'handles multiple free items with mixed prices' do
        cart_items = [
          CartItem.new(item: item1, amount: 2), # $100 each
          CartItem.new(item: item2, amount: 2), # $20 each
          CartItem.new(item: item3, amount: 2)  # $50 each
        ]
        # 6 items = 2 complete sets, 2 cheapest items free: 2 * $20 = $40
        expect(promotion.calculate_discount(cart_items)).to eq(40.0)
      end
    end

    context 'with percentage discounts' do
      let(:promotion) do
        BuyXGetY.new(
          id: 1,
          name: 'Buy 2 Get 1 (50% off)',
          buy_quantity: 2,
          get_quantity: 1,
          get_discount_percentage: 50,
          start_time: start_time,
          target_ids: [1]
        )
      end

      it 'applies percentage discount to free items' do
        cart_items = [CartItem.new(item: item1, amount: 3)]
        # 1 item at 50% off = $100 * 0.5 = $50
        expect(promotion.calculate_discount(cart_items)).to eq(50.0)
      end
    end

    context 'edge cases' do
      let(:promotion) do
        BuyXGetY.new(
          id: 1,
          name: 'Buy 3 Get 4',
          buy_quantity: 3,
          get_quantity: 4,
          start_time: start_time,
          target_ids: [1]
        )
      end

      it 'handles empty cart' do
        expect(promotion.calculate_discount([])).to eq(0)
      end

      it 'handles no applicable items' do
        cart_items = [CartItem.new(item: item2, amount: 10)]
        expect(promotion.calculate_discount(cart_items)).to eq(0)
      end

      it 'handles large quantities correctly' do
        cart_items = [CartItem.new(item: item1, amount: 21)]
        # 21 items = 3 complete sets (21 items total)
        # Each set: 3 paid + 4 free = 7 items
        # 3 sets = 12 free items = $1200
        expect(promotion.calculate_discount(cart_items)).to eq(1200.0)
      end
    end
  end

  describe '#to_s' do
    it 'displays free promotion correctly' do
      promotion = BuyXGetY.new(
        id: 1,
        name: 'Special Deal',
        buy_quantity: 2,
        get_quantity: 3,
        start_time: start_time
      )
      expect(promotion.to_s).to eq('Special Deal - Buy 2 get 3 (3 free)')
    end

    it 'displays percentage discount correctly' do
      promotion = BuyXGetY.new(
        id: 1,
        name: 'Half Price Deal',
        buy_quantity: 1,
        get_quantity: 2,
        get_discount_percentage: 50,
        start_time: start_time
      )
      expect(promotion.to_s).to eq('Half Price Deal - Buy 1 get 2 (2 at 50% off)')
    end
  end
end
