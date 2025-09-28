# frozen_string_literal: true

# Represents a category that items can belong to
class Category
  attr_reader :id, :name

  def initialize(id:, name:)
    @id = id
    @name = name
  end

  def ==(other)
    other.is_a?(Category) && id == other.id
  end
end
