class AddOrderIdToCustomerCard < ActiveRecord::Migration
  def change
    add_column :customer_cards, :order_id, :integer
  end
end
