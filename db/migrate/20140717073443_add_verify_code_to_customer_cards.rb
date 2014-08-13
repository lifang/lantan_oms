class AddVerifyCodeToCustomerCards < ActiveRecord::Migration
  def change
    add_column :customer_cards, :verify_code, :string
  end
end
