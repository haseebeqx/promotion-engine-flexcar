# frozen_string_literal: true

require_relative '../promotion'

# Flat fee discount promotion (e.g., $20 off)
class FlatDiscount < Promotion
  attr_reader :discount_amount

  def initialize(discount_amount:, **args)
    super(**args)
    @discount_amount = ensure_valid_discount_amount(discount_amount)
  end

  def calculate_discount(cart_item)
    return 0 unless can_apply_to?(cart_item)

    # Apply flat discount, but don't exceed the item's price
    [discount_amount, cart_item.original_price].min
  end

  def can_apply_to?(cart_item)
    applicable_to_item?(cart_item.item)
  end

  def to_s
    "#{name} - $#{discount_amount} off"
  end

  private

  def ensure_valid_discount_amount(amount)
    raise ArgumentError, 'Discount amount must be a positive number' unless amount.is_a?(Numeric) && amount.positive?

    amount
  end
end
