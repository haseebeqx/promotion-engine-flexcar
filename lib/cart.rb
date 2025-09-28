# frozen_string_literal: true

require_relative 'cart_item'
require_relative 'promotion_engine'

# Represents a shopping cart that can hold items and apply promotions
class Cart
  attr_reader :items, :promotion_engine

  def initialize(promotion_engine: nil)
    @items = []
    @promotion_engine = promotion_engine || PromotionEngine.new
  end

  def add_item(item, amount)
    cart_item = CartItem.new(item:, amount:)
    @items << cart_item
    apply_best_promotions
    cart_item
  end

  def remove_item(item_id)
    removed_items = @items.select { |cart_item| cart_item.item.id == item_id }
    @items.reject! { |cart_item| cart_item.item.id == item_id }
    apply_best_promotions unless removed_items.empty?
    removed_items
  end

  def clear
    @items.clear
  end

  def total_original_price
    @items.sum(&:original_price)
  end

  def total_discounted_price
    @items.sum(&:discounted_price)
  end

  def total_savings
    total_original_price - total_discounted_price
  end

  def item_count
    @items.sum(&:quantity)
  end

  def total_weight
    @items.sum(&:weight)
  end

  def empty?
    @items.empty?
  end

  def summary
    return 'Cart is empty' if empty?

    summary_lines = ['Cart Summary:']
    summary_lines << '=' * 40

    @items.each do |cart_item|
      summary_lines << cart_item.to_s
    end

    summary_lines << '-' * 40
    summary_lines << "Original Total: $#{total_original_price}"
    summary_lines << "Total Savings: $#{total_savings}" if total_savings.positive?
    summary_lines << "Final Total: $#{total_discounted_price}"

    summary_lines.join("\n")
  end

  private

  def apply_best_promotions
    # Clear existing promotions
    @items.each(&:remove_promotion)

    # Apply best promotions through the promotion engine
    @promotion_engine&.apply_best_promotions(self)
  end
end
