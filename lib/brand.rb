# frozen_string_literal: true

# Represents a brand that can be associated with items
class Brand
  attr_reader :id, :name

  def initialize(id:, name:)
    @id = id
    @name = name
  end

  def ==(other)
    other.is_a?(Brand) && id == other.id
  end

  def to_s
    name
  end
end
