class AddUserIdToShowoffs < ActiveRecord::Migration[5.0]
  def change
    add_column :showoffs, :user_id, :integer
  end
end
