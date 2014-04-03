class CreateOrderProdRelations < ActiveRecord::Migration
  #产品订单表
  def change
    create_table :order_prod_relations do |t|
      t.integer :order_id
      t.integer :product_id
      t.integer :pro_num   #产品数量
      t.float :price   #价格
      t.float :total_price #订单每项商品的总价
      t.float :t_price #订单每项商品的成本价
      t.integer :return_types, :default=>0
      
      t.timestamps
    end

    add_index :order_prod_relations, :order_id
    add_index :order_prod_relations, :product_id
  end
end
