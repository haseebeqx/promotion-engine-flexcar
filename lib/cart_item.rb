# frozen_string_literal: true

require_relative 'item'

# Represents an item in the cart with quantity/weight and pricing information
class CartItem
  attr_reader :item, :amount, :original_price, :discounted_price, :applied_promotion

  def initialize(item:, amount:)
    @item = item
    @amount = validate_amount(amount)
    @original_price = calculate_original_price
    @discounted_price = @original_price
    @applied_promotion = nil
  end

  def apply_promotion(promotion, discount_amount)
    @applied_promotion = promotion
    @discounted_price = [@original_price - discount_amount, 0].max
  end

  def remove_promotion
    @applied_promotion = nil
    @discounted_price = @original_price
  end

  def has_promotion?
    !@applied_promotion.nil?
  end

  def savings
    @original_price - @discounted_price
  end

  def quantity
    item.sold_by_quantity? ? amount : 1
  end

  def weight
    item.sold_by_weight? ? amount : 0
  end

  def to_s
    if item.sold_by_quantity?
      "#{item.name} x#{quantity}"
    else
      "#{item.name} #{weight}kg"
    end
  end

  private

  def validate_amount(amount)
    raise ArgumentError, 'Amount must be a positive number' unless amount.is_a?(Numeric) && amount.positive?

    amount
  end

  def calculate_original_price
    item.price * amount
  end
end
