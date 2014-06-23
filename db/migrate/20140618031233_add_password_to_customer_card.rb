class AddPasswordToCustomerCard < ActiveRecord::Migration
  def change
    add_column :customer_cards, :password, :string    #入职时间
  end
end
