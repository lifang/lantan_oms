class AddindexToCustomerCards < ActiveRecord::Migration
  def change
    add_index :customer_cards,:customer_id
    add_index :customer_cards,:card_id
  end
end
