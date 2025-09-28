# frozen_string_literal: true

# Base class for all promotions
class Promotion
  attr_reader :id, :name, :start_time, :end_time, :target_type, :target_ids

  TARGET_TYPES = %i[item category].freeze

  def initialize(id:, name:, start_time:, end_time: nil, target_type: :item, target_ids: [])
    @id = id
    @name = name
    @start_time = start_time
    @end_time = end_time
    @target_type = ensure_valid_target_type(target_type)
    @target_ids = Array(target_ids)
  end

  def active?
    current_time = Time.now
    current_time >= start_time && (end_time.nil? || current_time <= end_time)
  end

  def applicable_to_item?(item)
    return false unless active?

    case target_type
    when :item
      target_ids.empty? || target_ids.include?(item.id)
    when :category
      target_ids.empty? || item.categories.any? { |cat| target_ids.include?(cat.id) }
    end
  end

  # Abstract method - must be implemented by subclasses
  def calculate_discount(cart_item)
    raise NotImplementedError, 'Subclasses must implement calculate_discount'
  end

  # Abstract method - must be implemented by subclasses
  def can_apply_to?(cart_item)
    raise NotImplementedError, 'Subclasses must implement can_apply_to?'
  end

  private

  def ensure_valid_target_type(type)
    unless TARGET_TYPES.include?(type)
      raise ArgumentError, "Invalid target type: #{type}. Must be one of #{TARGET_TYPES}"
    end

    type
  end
end
