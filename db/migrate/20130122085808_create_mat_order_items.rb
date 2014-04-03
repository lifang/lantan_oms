class CreateMatOrderItems < ActiveRecord::Migration
  #物料订单条目表
  def change
    create_table :mat_order_items do |t|
      t.integer :material_order_id
      t.integer :material_id
      t.integer :material_num
      t.decimal :price,:precision=>"20,2",:default=>0
      t.timestamps
    end

    add_index :mat_order_items, :material_order_id
    add_index :mat_order_items, :material_id
  end
end
