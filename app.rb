# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/json'
require_relative 'lib/promotion_system'

# Enable method override for DELETE requests
use Rack::MethodOverride

# Initialize the promotion system (in-memory storage)
configure do
  set :system, PromotionSystem.new
  set :cart, nil
end

# Helper methods
helpers do
  def system
    settings.system
  end

  def cart
    settings.cart ||= system.create_cart
  end

  def format_price(price)
    format('%.2f', price)
  end

  def format_time(time)
    time.strftime('%Y-%m-%d %H:%M')
  end
end

# Home page - redirect to admin dashboard
get '/' do
  redirect '/admin'
end

# Admin Dashboard - consolidated management interface
get '/admin' do
  @categories = system.categories.values
  @brands = system.brands.values
  @items = system.items.values
  @promotions = system.active_promotions
  erb :admin
end

# Shopping Interface - customer-facing cart interface (Suppose)
get '/shop' do
  @items = system.items.values
  @cart = cart
  erb :shop
end

post '/categories' do
  id = params[:id].to_i
  name = params[:name]
  system.create_category(id: id, name: name)
  redirect '/admin?tab=categories'
end

post '/brands' do
  id = params[:id].to_i
  name = params[:name]
  system.create_brand(id: id, name: name)
  redirect '/admin?tab=brands'
end

post '/items' do
  id = params[:id].to_i
  name = params[:name]
  price = params[:price].to_f
  sale_type = params[:sale_type].to_sym
  category_ids = params[:category_ids] ? params[:category_ids].map(&:to_i) : []
  brand_id = params[:brand_id].to_i if params[:brand_id] && !params[:brand_id].empty?

  system.create_item(
    id: id,
    name: name,
    price: price,
    sale_type: sale_type,
    category_ids: category_ids,
    brand_id: brand_id
  )
  redirect '/admin?tab=items'
end

post '/promotions/flat_discount' do
  system.create_flat_discount(
    id: params[:id].to_i,
    name: params[:name],
    discount_amount: params[:discount_amount].to_f,
    start_time: Time.parse(params[:start_time]),
    end_time: params[:end_time] && !params[:end_time].empty? ? Time.parse(params[:end_time]) : nil,
    target_type: params[:target_type].to_sym,
    target_ids: params[:target_ids].split(',').map(&:to_i)
  )
  redirect '/admin?tab=promotions'
end

post '/promotions/percentage_discount' do
  system.create_percentage_discount(
    id: params[:id].to_i,
    name: params[:name],
    discount_percentage: params[:discount_percentage].to_f,
    start_time: Time.parse(params[:start_time]),
    end_time: params[:end_time] && !params[:end_time].empty? ? Time.parse(params[:end_time]) : nil,
    target_type: params[:target_type].to_sym,
    target_ids: params[:target_ids].split(',').map(&:to_i)
  )
  redirect '/admin?tab=promotions'
end

post '/promotions/buy_x_get_y' do
  system.create_buy_x_get_y(
    id: params[:id].to_i,
    name: params[:name],
    buy_quantity: params[:buy_quantity].to_i,
    get_quantity: params[:get_quantity].to_i,
    get_discount_percentage: params[:get_discount_percentage].to_f,
    start_time: Time.parse(params[:start_time]),
    end_time: params[:end_time] && !params[:end_time].empty? ? Time.parse(params[:end_time]) : nil,
    target_type: params[:target_type].to_sym,
    target_ids: params[:target_ids].split(',').map(&:to_i)
  )
  redirect '/admin?tab=promotions'
end

post '/promotions/weight_threshold' do
  system.create_weight_threshold(
    id: params[:id].to_i,
    name: params[:name],
    threshold_weight: params[:threshold_weight].to_f,
    discount_percentage: params[:discount_percentage].to_f,
    start_time: Time.parse(params[:start_time]),
    end_time: params[:end_time] && !params[:end_time].empty? ? Time.parse(params[:end_time]) : nil,
    target_type: params[:target_type].to_sym,
    target_ids: params[:target_ids].split(',').map(&:to_i)
  )
  redirect '/admin?tab=promotions'
end

delete '/promotions/:id' do
  system.remove_promotion(params[:id].to_i)
  redirect '/admin?tab=promotions'
end

post '/cart/add' do
  item_id = params[:item_id].to_i
  amount = params[:amount].to_f
  item = system.get_item(item_id)
  cart.add_item(item, amount) if item
  redirect '/shop'
end

post '/cart/remove/:item_id' do
  cart.remove_item(params[:item_id].to_i)
  redirect '/shop'
end

post '/cart/clear' do
  cart.clear
  redirect '/shop'
end

# API endpoints for AJAX (optional)
get '/api/cart/summary' do
  content_type :json
  {
    items: cart.items.map do |cart_item|
      {
        id: cart_item.item.id,
        name: cart_item.item.name,
        amount: cart_item.amount,
        sale_type: cart_item.item.sale_type,
        original_price: cart_item.original_price,
        discounted_price: cart_item.discounted_price,
        promotion: cart_item.applied_promotion&.name
      }
    end,
    total_original_price: cart.total_original_price,
    total_discounted_price: cart.total_discounted_price,
    total_savings: cart.total_savings
  }.to_json
end
