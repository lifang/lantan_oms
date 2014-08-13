class AddCustomerPackageCardIdToOrderProdRelations < ActiveRecord::Migration
  def change
    add_column :order_prod_relations, :customer_pcard_id, :integer
  end
end
