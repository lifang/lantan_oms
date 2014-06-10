class DropCulumToOrders < ActiveRecord::Migration
  def change
     remove_column :orders, :c_pcard_relation_id
     remove_column :orders, :c_svc_relation_id
     add_column :order_prod_relations, :prod_types, :integer
     rename_column :order_prod_relations,:product_id,:item_id
  end
end
