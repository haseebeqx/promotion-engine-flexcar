# frozen_string_literal: true

require_relative 'brand'
require_relative 'category'
require_relative 'item'
require_relative 'cart'
require_relative 'cart_item'
require_relative 'promotion_engine'
require_relative 'promotion'
require_relative 'promotions/flat_discount'
require_relative 'promotions/percentage_discount'
require_relative 'promotions/buy_x_get_y'
require_relative 'promotions/weight_threshold'

# Main entry point for the promotion system
class PromotionSystem
  attr_reader :promotion_engine, :brands, :categories, :items

  def initialize
    @promotion_engine = PromotionEngine.new
    @brands = {}
    @categories = {}
    @items = {}
  end

  # Brand management
  def create_brand(id:, name:)
    brand = Brand.new(id:, name:)
    @brands[id] = brand
    brand
  end

  def get_brand(id)
    @brands[id]
  end

  # Category management
  def create_category(id:, name:)
    category = Category.new(id:, name:)
    @categories[id] = category
    category
  end

  def get_category(id)
    @categories[id]
  end

  # Item management
  def create_item(id:, name:, price:, sale_type:, category_ids: [], brand_id: nil)
    categories = Array(category_ids).map { |cat_id| get_category(cat_id) }.compact
    brand = brand_id ? get_brand(brand_id) : nil

    item = Item.new(
      id:,
      name:,
      price:,
      sale_type:,
      categories:,
      brand:
    )

    @items[id] = item
    item
  end

  def get_item(id)
    @items[id]
  end

  # Promotion management
  def remove_promotion(promotion_id)
    @promotion_engine.remove_promotion(promotion_id)
  end

  def active_promotions
    @promotion_engine.active_promotions
  end

  # Cart creation
  def create_cart
    Cart.new(promotion_engine: @promotion_engine)
  end

  # Convenience methods for creating and adding promotions
  def create_flat_discount(id:, name:, discount_amount:, start_time:, end_time: nil, target_type: :item, target_ids: [])
    promotion = FlatDiscount.new(
      id:,
      name:,
      discount_amount:,
      start_time:,
      end_time:,
      target_type:,
      target_ids:
    )
    @promotion_engine.add_promotion(promotion)
    promotion
  end

  def create_percentage_discount(id:, name:, discount_percentage:, start_time:, end_time: nil, target_type: :item,
                                 target_ids: [])
    promotion = PercentageDiscount.new(
      id:,
      name:,
      discount_percentage:,
      start_time:,
      end_time:,
      target_type:,
      target_ids:
    )
    @promotion_engine.add_promotion(promotion)
    promotion
  end

  def create_buy_x_get_y(id:, name:, buy_quantity:, get_quantity:, start_time:, get_discount_percentage: 100,
                         end_time: nil, target_type: :item, target_ids: [])
    promotion = BuyXGetY.new(
      id:,
      name:,
      buy_quantity:,
      get_quantity:,
      get_discount_percentage:,
      start_time:,
      end_time:,
      target_type:,
      target_ids:
    )
    @promotion_engine.add_promotion(promotion)
    promotion
  end

  def create_weight_threshold(id:, name:, threshold_weight:, discount_percentage:, start_time:, end_time: nil,
                              target_type: :item, target_ids: [])
    promotion = WeightThreshold.new(
      id:,
      name:,
      threshold_weight:,
      discount_percentage:,
      start_time:,
      end_time:,
      target_type:,
      target_ids:
    )
    @promotion_engine.add_promotion(promotion)
    promotion
  end
end
