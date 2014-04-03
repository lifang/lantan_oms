class CreateWorkOrders < ActiveRecord::Migration
  #工单表
  def change
    create_table :work_orders do |t|
      t.integer :station_id
      t.integer :status
      t.integer :order_id
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :current_day
      t.float :runtime   #花费时长
      t.float :violation_num   #违规次数
      t.string :violation_reason  
      t.float :water_num
      t.float :electricity_num
      t.integer :store_id
      t.integer :cost_time

      t.timestamps
    end

    add_index :work_orders, :station_id
    add_index :work_orders, :status
    add_index :work_orders, :order_id
    add_index :work_orders, :current_day
    add_index :work_orders, :store_id
  end
end
