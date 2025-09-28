# frozen_string_literal: true

require_relative '../promotion'

# Weight threshold discount promotion (e.g., buy more than 100g and get 50% off)
class WeightThreshold < Promotion
  attr_reader :threshold_weight, :discount_percentage

  def initialize(threshold_weight:, discount_percentage:, **args)
    super(**args)
    @threshold_weight = ensure_valid_threshold_weight(threshold_weight)
    @discount_percentage = ensure_valid_discount_percentage(discount_percentage)
  end

  def calculate_discount(cart_item)
    return 0 unless can_apply_to?(cart_item)
    return 0 unless cart_item.weight >= threshold_weight

    cart_item.original_price * (discount_percentage / 100.0)
  end

  def can_apply_to?(cart_item)
    applicable_to_item?(cart_item.item) && cart_item.item.sold_by_weight?
  end

  def to_s
    "#{name} - #{discount_percentage}% off when buying #{threshold_weight}+ grams"
  end

  private

  def ensure_valid_threshold_weight(weight)
    raise ArgumentError, 'Threshold weight must be a positive number' unless weight.is_a?(Numeric) && weight.positive?

    weight
  end

  def ensure_valid_discount_percentage(percentage)
    unless percentage.is_a?(Numeric) && percentage.positive? && percentage <= 99
      raise ArgumentError, 'Discount percentage must be between 0 and 99'
    end

    percentage
  end
end
