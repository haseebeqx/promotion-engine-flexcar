# frozen_string_literal: true

require_relative 'promotion'
require_relative 'promotions/flat_discount'
require_relative 'promotions/percentage_discount'
require_relative 'promotions/buy_x_get_y'
require_relative 'promotions/weight_threshold'

# Engine responsible for finding and applying the best promotions to cart items
class PromotionEngine
  attr_reader :promotions

  def initialize(promotions = [])
    @promotions = promotions
  end

  def add_promotion(promotion)
    @promotions << promotion unless @promotions.include?(promotion)
  end

  def remove_promotion(promotion_id)
    @promotions.reject! { |p| p.id == promotion_id }
  end

  def active_promotions
    @promotions.select(&:active?)
  end

  def apply_best_promotions(cart)
    return if cart.items.empty?

    # Generate all possible promotion scenarios
    scenarios = generate_promotion_scenarios(cart)

    # Find the scenario with maximum total savings
    best_scenario = scenarios.max_by { |scenario| scenario[:total_savings] }

    # Apply the best scenario
    apply_scenario(cart, best_scenario) if best_scenario && best_scenario[:total_savings].positive?
  end

  private

  def group_items_by_identity(cart_items)
    cart_items.group_by { |cart_item| cart_item.item.id }
  end

  def calculate_individual_promotion_discount(promotion, cart_items)
    # Individual promotions work on each item separately
    cart_items.sum { |cart_item| promotion.calculate_discount(cart_item) }
  end

  def apply_buy_x_get_y_promotion(cart_items, promotion, total_discount)
    # Distribute the discount across applicable items
    applicable_items = cart_items.select { |item| promotion.can_apply_to?(item) }
    return if applicable_items.empty?

    # Apply discount proportionally based on original price
    total_original_price = applicable_items.sum(&:original_price)

    applicable_items.each do |cart_item|
      if total_original_price.positive?
        item_discount = total_discount * (cart_item.original_price / total_original_price)
        cart_item.apply_promotion(promotion, item_discount)
      end
    end
  end

  def apply_individual_promotion(cart_items, promotion)
    cart_items.each do |cart_item|
      if promotion.can_apply_to?(cart_item)
        discount = promotion.calculate_discount(cart_item)
        cart_item.apply_promotion(promotion, discount) if discount.positive?
      end
    end
  end

  def generate_promotion_scenarios(cart)
    scenarios = []

    # Scenario 1: No promotions (baseline)
    scenarios << { type: :none, promotions: [], total_savings: 0 }

    # Scenario 2: Each BuyXGetY promotion individually
    buy_x_get_y_promotions = active_promotions.select { |p| p.is_a?(BuyXGetY) }
    buy_x_get_y_promotions.each do |promotion|
      scenario = evaluate_buy_x_get_y_scenario(cart, promotion)
      scenarios << scenario if scenario[:total_savings].positive?
    end

    # Scenario 3: Individual promotions only (no BuyXGetY)
    individual_scenario = evaluate_individual_promotions_scenario(cart)
    scenarios << individual_scenario if individual_scenario[:total_savings].positive?

    # Scenario 4: Optimal combination of BuyXGetY promotions by category
    if buy_x_get_y_promotions.length > 1
      combined_scenario = evaluate_combined_buy_x_get_y_scenario(cart, buy_x_get_y_promotions)
      scenarios << combined_scenario if combined_scenario[:total_savings].positive?
    end

    scenarios
  end

  def evaluate_buy_x_get_y_scenario(cart, promotion)
    applicable_items = cart.items.select { |item| promotion.can_apply_to?(item) }
    total_discount = promotion.calculate_discount(applicable_items)

    {
      type: :buy_x_get_y,
      promotions: [{ promotion: promotion, items: applicable_items, discount: total_discount }],
      total_savings: total_discount
    }
  end

  def evaluate_combined_buy_x_get_y_scenario(cart, buy_x_get_y_promotions)
    # Group items by the categories/items they target
    promotion_groups = {}

    buy_x_get_y_promotions.each do |promotion|
      applicable_items = cart.items.select { |item| promotion.can_apply_to?(item) }
      next if applicable_items.empty?

      discount = promotion.calculate_discount(applicable_items)
      next unless discount.positive?

      # Group by target (category or item IDs)
      target_key = "#{promotion.target_type}_#{promotion.target_ids.sort.join(',')}"

      next unless !promotion_groups[target_key] || promotion_groups[target_key][:discount] < discount

      promotion_groups[target_key] = {
        promotion: promotion,
        items: applicable_items,
        discount: discount
      }
    end

    # Combine the best promotion for each target group
    total_savings = promotion_groups.values.sum { |group| group[:discount] }

    {
      type: :combined_buy_x_get_y,
      promotions: promotion_groups.values,
      total_savings: total_savings
    }
  end

  def evaluate_individual_promotions_scenario(cart)
    total_savings = 0
    promotion_applications = []

    # Group items by identity and find best individual promotion for each group
    item_groups = group_items_by_identity(cart.items)
    individual_promotions = active_promotions.reject { |p| p.is_a?(BuyXGetY) }

    item_groups.each_value do |cart_items|
      best_promotion, best_discount = find_best_individual_promotion_for_items(cart_items, individual_promotions)

      next unless best_promotion && best_discount.positive?

      promotion_applications << {
        promotion: best_promotion,
        items: cart_items,
        discount: best_discount
      }
      total_savings += best_discount
    end

    {
      type: :individual,
      promotions: promotion_applications,
      total_savings: total_savings
    }
  end

  def find_best_individual_promotion_for_items(cart_items, promotions)
    best_promotion = nil
    best_discount = 0

    promotions.each do |promotion|
      # Skip if promotion doesn't apply to any of these items
      next unless cart_items.any? { |item| promotion.can_apply_to?(item) }

      discount = calculate_individual_promotion_discount(promotion, cart_items)

      if discount > best_discount
        best_promotion = promotion
        best_discount = discount
      end
    end

    [best_promotion, best_discount]
  end

  def apply_scenario(cart, scenario)
    # Clear any existing promotions
    cart.items.each(&:remove_promotion)

    # Apply the promotions from the best scenario
    scenario[:promotions].each do |promo_app|
      case scenario[:type]
      when :buy_x_get_y, :combined_buy_x_get_y
        apply_buy_x_get_y_promotion(promo_app[:items], promo_app[:promotion], promo_app[:discount])
      when :individual
        apply_individual_promotion(promo_app[:items], promo_app[:promotion])
      end
    end
  end
end
