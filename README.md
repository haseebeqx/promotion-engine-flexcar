# E-commerce Inventory and Promotions Engine

A comprehensive Ruby-based inventory and promotions engine for e-commerce platforms. This system allows businesses to manage items, create various types of promotions, and automatically apply the best available discounts to shopping carts.

## Features

### Item Management
- Items can be sold by **weight** or **quantity**
- Items can belong to **multiple categories**
- Items can have **brands**
- Multiple instances of the same item can be added to cart
- No tax calculations (as per requirements)

### Promotion Types
1. **Flat Fee Discount** - Fixed dollar amount off (e.g., $20 off)
2. **Percentage Discount** - Percentage off item price (e.g., 10% off)
3. **Buy X Get Y** - Purchase-based discounts (e.g., Buy 1 Get 1 Free, Buy 3 Get 1 50% off)
4. **Weight Threshold** - Discounts based on weight purchased (e.g., 50% off when buying 100g+)

### Promotion Rules
- Promotions can target individual items or entire categories
- Promotions must have a start time and may have an end time
- Multiple promotions can be applied if they target different items
- Each item can only have one promotion applied
- Only one instance of each promotion can be applied at a time
- System automatically applies the best available promotion

### Cart Features
- Add and remove items from cart
- View cart contents and totals
- Automatic calculation of best prices with promotions
- Real-time promotion application

## Requirements

- Ruby 3.0 or higher
- Bundler gem

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Verify installation by running tests:
   ```bash
   bundle exec rspec
   ```

## Usage

### Basic Setup

```ruby
require_relative 'lib/promotion_system'

# Create the main system
system = PromotionSystem.new

# Create categories
electronics = system.create_category(id: 1, name: 'Electronics')
food = system.create_category(id: 2, name: 'Food')
accessories = system.create_category(id: 3, name: 'Accessories')

# Create brands
apple = system.create_brand(id: 1, name: 'Apple')
samsung = system.create_brand(id: 2, name: 'Samsung')

# Create items
iphone = system.create_item(
  id: 1,
  name: 'iPhone 15',
  price: 999.99,
  sale_type: :quantity,
  category_ids: [1],
  brand_id: 1
)

apples = system.create_item(
  id: 2,
  name: 'Fresh Apples',
  price: 3.99,
  sale_type: :weight,
  category_ids: [2]
)
```

### Multi-Category Items

Items can belong to multiple categories, which allows them to be targeted by promotions from any of their categories:

```ruby
# Create an item that belongs to both Electronics and Accessories categories
phone_case = system.create_item(
  id: 3,
  name: 'Smart Phone Case',
  price: 50.0,
  sale_type: :quantity,
  category_ids: [1, 3] # Both Electronics and Accessories
)

# This item can now be targeted by promotions for either category
```

### Creating Promotions

```ruby
# Flat discount - $100 off iPhone
system.create_flat_discount(
  id: 1,
  name: '$100 off iPhone',
  discount_amount: 100,
  start_time: Time.now,
  end_time: Time.now + (30 * 24 * 3600), # 30 days
  target_ids: [1] # iPhone ID
)

# Percentage discount - 20% off all electronics
system.create_percentage_discount(
  id: 2,
  name: '20% off Electronics',
  discount_percentage: 20,
  start_time: Time.now,
  target_type: :category,
  target_ids: [1] # Electronics category
)

# Buy 2 Get 1 Free on electronics
system.create_buy_x_get_y(
  id: 3,
  name: 'Buy 2 Get 1 Free Electronics',
  buy_quantity: 2,
  get_quantity: 1,
  get_discount_percentage: 100, # 100% = free
  start_time: Time.now,
  target_type: :category,
  target_ids: [1]
)

# Weight threshold - 25% off when buying 5kg+ of food
system.create_weight_threshold(
  id: 4,
  name: 'Bulk Food Discount',
  threshold_weight: 5,
  discount_percentage: 25,
  start_time: Time.now,
  target_type: :category,
  target_ids: [2]
)
```

### Using the Shopping Cart

```ruby
# Create a cart
cart = system.create_cart

# Add items
cart.add_item(iphone, 1)           # Add 1 iPhone
cart.add_item(apples, 6)           # Add 6kg of apples

# View cart summary
puts cart.summary

# Check totals
puts "Original Total: $#{cart.total_original_price}"
puts "Final Total: $#{cart.total_discounted_price}"
puts "You Saved: $#{cart.total_savings}"

# Remove items
cart.remove_item(1) # Remove all iPhones

# Clear cart
cart.clear
```

## Project Structure

```
lib/
├── promotion_system.rb      # Main entry point
├── cart.rb                  # Shopping cart implementation
├── cart_item.rb            # Individual cart item with promotions
├── item.rb                 # Product/item definition
├── category.rb             # Item categorization
├── brand.rb                # Brand management
├── promotion.rb            # Base promotion class
├── promotion_engine.rb     # Promotion logic and optimization
└── promotions/             # Specific promotion types
    ├── flat_discount.rb
    ├── percentage_discount.rb
    ├── buy_x_get_y.rb
    └── weight_threshold.rb

spec/                       # Test files
├── promotion_system_spec.rb
├── promotion_engine_spec.rb
├── item_spec.rb
├── brand_spec.rb
├── promotions_spec.rb
└── promotions/            # Promotion-specific tests
    ├── flat_discount_spec.rb
    ├── percentage_discount_spec.rb
    ├── buy_x_get_y_spec.rb
    └── weight_threshold_spec.rb
```

## Architecture

### Core Classes

- **PromotionSystem** - Main entry point and factory for all components
- **Item** - Represents products that can be sold
- **Category** - Groups items together
- **Brand** - Represents item manufacturers
- **Cart** - Shopping cart that holds items and applies promotions
- **CartItem** - Individual item instance in cart with quantity/weight
- **PromotionEngine** - Handles promotion logic and application

### Promotion Classes

- **Promotion** - Base class for all promotions
- **FlatDiscount** - Fixed dollar amount discounts
- **PercentageDiscount** - Percentage-based discounts  
- **BuyXGetY** - Quantity-based promotional discounts
- **WeightThreshold** - Weight-based promotional discounts

## Additional Examples

For more comprehensive examples and test cases, see the test files in the `spec/` directory, particularly:
- `spec/promotion_system_spec.rb` - Integration examples and cart functionality
- `spec/promotion_engine_spec.rb` - Complex promotion scenarios and optimization logic
- `spec/promotions/` - Individual promotion type tests with detailed scenarios

### Adding New Promotion Types

To add a new promotion type:

1. Create a new class in `lib/promotions/` that inherits from `Promotion`
2. Implement the required methods: `calculate_discount` and `can_apply_to?`
3. Add the promotion to `PromotionSystem` with a factory method
4. Create comprehensive tests in `spec/promotions/`

## License

This project is available for use under standard software licensing terms.
