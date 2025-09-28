# frozen_string_literal: true

require_relative 'brand'
require_relative 'category'

# Represents an item that can be sold by weight or quantity
class Item
  attr_reader :id, :name, :price, :sale_type, :categories, :brand

  SALE_TYPES = %i[weight quantity].freeze

  def initialize(id:, name:, price:, sale_type:, categories: [], brand: nil)
    @id = id
    @name = name
    @price = price
    @sale_type = validate_sale_type(sale_type)
    @categories = Array(categories)
    @brand = brand
  end

  def sold_by_weight?
    sale_type == :weight
  end

  def sold_by_quantity?
    sale_type == :quantity
  end

  def ==(other)
    other.is_a?(Item) && id == other.id
  end

  private

  def validate_sale_type(type)
    raise ArgumentError, "Invalid sale type: #{type}. Must be one of #{SALE_TYPES}" unless SALE_TYPES.include?(type)

    type
  end
end
