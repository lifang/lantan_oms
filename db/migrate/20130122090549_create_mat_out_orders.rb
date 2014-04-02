class CreateMatOutOrders < ActiveRecord::Migration
  #物料出库单
  def change
    create_table :mat_out_orders do |t|
      t.integer :material_id
      t.integer :staff_id
      t.integer :material_num
      t.float :price
      t.integer :material_order_id
      t.integer :types, :limit => 1 #出库类型
      t.integer :store_id
      t.timestamps
    end

    add_index :mat_out_orders, :material_id
    add_index :mat_out_orders, :staff_id
    add_index :mat_out_orders, :material_order_id
  end
end
