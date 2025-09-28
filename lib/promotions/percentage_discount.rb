# frozen_string_literal: true

require_relative '../promotion'

# Percentage discount promotion (e.g., 10% off)
class PercentageDiscount < Promotion
  attr_reader :discount_percentage

  def initialize(discount_percentage:, **args)
    super(**args)
    @discount_percentage = ensure_valid_discount_percentage(discount_percentage)
  end

  def calculate_discount(cart_item)
    return 0 unless can_apply_to?(cart_item)

    cart_item.original_price * (discount_percentage / 100.0)
  end

  def can_apply_to?(cart_item)
    applicable_to_item?(cart_item.item)
  end

  def to_s
    "#{name} - #{discount_percentage}% off"
  end

  private

  def ensure_valid_discount_percentage(percentage)
    unless percentage.is_a?(Numeric) && percentage.positive? && percentage <= 100
      raise ArgumentError, 'Discount percentage must be between 0 and 100'
    end

    percentage
  end
end
