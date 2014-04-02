class CreateReturnOrders < ActiveRecord::Migration
  def change
    create_table :tech_orders do |t|
      t.integer :return_types, :default=>0
      t.integer :return_direct
      t.decimal :return_fee, :default =>0,:precision=>"20,2"
      t.integer :return_staff_id
      t.integer :return_reason
      t.integer :order_id
      t.integer :store_id

      t.timestamps
    end
  end
end
