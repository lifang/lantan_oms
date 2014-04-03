class CreateOrderProdRelations < ActiveRecord::Migration
  #产品订单表
  def change
    create_table :order_prod_relations do |t|
      t.integer :order_id
      t.integer :product_id
      t.integer :pro_num   #产品数量
      t.decimal :price,:precision=>"20,2",:default=>0   #价格
      t.decimal :total_price,:precision=>"20,2",:default=>0 #订单每项商品的总价
      t.decimal :t_price,:precision=>"20,2",:default=>0 #订单每项商品的成本价
      
      t.timestamps
    end

    add_index :order_prod_relations, :order_id
    add_index :order_prod_relations, :product_id
  end
end
