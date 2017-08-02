class AddStoreIdtoProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :store_id, :integer
  end
end
