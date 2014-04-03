class CreateMatOutOrders < ActiveRecord::Migration
  #物料出库单
  def change
    create_table :mat_out_orders do |t|
      t.integer :material_id
      t.integer :staff_id
      t.integer :material_num
      t.decimal :price,:precision=>"20,2",:default=>0
      t.integer :material_order_id
      t.integer :types, :limit => 1 #出库类型
      t.datetime :created_at
      t.integer :store_id
    end

    add_index :mat_out_orders, :material_id
    add_index :mat_out_orders, :staff_id
    add_index :mat_out_orders, :material_order_id
    add_index :mat_out_orders, :created_at
  end
end
