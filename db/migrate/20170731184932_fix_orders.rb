class FixOrders < ActiveRecord::Migration[5.0]
  def change
    remove_column :orders, :delivery_address, :string
    add_column :orders, :pickup_location, :string
  end
end
