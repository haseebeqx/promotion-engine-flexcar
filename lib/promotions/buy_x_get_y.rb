# frozen_string_literal: true

require_relative '../promotion'

# Buy X Get Y promotion (e.g., Buy 2 get 1 free, Buy 3 get 1 at 50% off)
class BuyXGetY < Promotion
  attr_reader :buy_quantity, :get_quantity, :get_discount_percentage

  def initialize(buy_quantity:, get_quantity:, get_discount_percentage: 100, **args)
    super(**args)
    @buy_quantity = validate_quantity(buy_quantity, 'buy_quantity')
    @get_quantity = validate_quantity(get_quantity, 'get_quantity')
    @get_discount_percentage = validate_discount_percentage(get_discount_percentage)
  end

  def calculate_discount(cart_items)
    return 0 if cart_items.empty?

    applicable_items = cart_items.select { |item| can_apply_to?(item) }
    return 0 if applicable_items.empty?

    total_quantity = applicable_items.sum(&:quantity)
    min_items_for_discount = buy_quantity + 1
    return 0 if total_quantity < min_items_for_discount

    # Calculate complete promotion sets
    items_per_promotion_set = buy_quantity + get_quantity
    complete_promotion_sets = total_quantity / items_per_promotion_set
    remaining_items = total_quantity % items_per_promotion_set

    # Handle partial promotion sets: if remaining items > buy_quantity,
    # customer gets additional free items (up to get_quantity limit)
    partial_free_items = 0
    if remaining_items > buy_quantity
      partial_free_items = remaining_items - buy_quantity
      partial_free_items = [partial_free_items, get_quantity].min
    end

    total_free_items = (complete_promotion_sets * get_quantity) + partial_free_items

    # Apply discount to cheapest items
    sorted_items = applicable_items.sort_by { |item| item.item.price }

    discount = 0
    remaining_free_items = total_free_items

    sorted_items.each do |cart_item|
      break if remaining_free_items <= 0

      items_to_discount = [cart_item.quantity, remaining_free_items].min
      item_discount = (cart_item.item.price * items_to_discount * get_discount_percentage / 100.0)
      discount += item_discount
      remaining_free_items -= items_to_discount
    end

    discount
  end

  def can_apply_to?(cart_item)
    applicable_to_item?(cart_item.item) &&
      cart_item.item.sold_by_quantity?
  end

  def to_s
    if get_discount_percentage == 100
      "#{name} - Buy #{buy_quantity} get #{get_quantity} (#{get_quantity} free)"
    else
      "#{name} - Buy #{buy_quantity} get #{get_quantity} (#{get_quantity} at #{get_discount_percentage}% off)"
    end
  end

  private

  def validate_quantity(quantity, field_name)
    raise ArgumentError, "#{field_name} must be a positive integer" unless quantity.is_a?(Integer) && quantity.positive?

    quantity
  end

  def validate_discount_percentage(percentage)
    unless percentage.is_a?(Numeric) && percentage.positive? && percentage <= 100
      raise ArgumentError, 'get_discount_percentage must be between 0 and 100'
    end

    percentage
  end
end
