class CreateGoalSales < ActiveRecord::Migration
  #销售额度表
  def change
    create_table :goal_sales do |t|
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :store_id

      t.timestamps
    end
    add_index :goal_sales, :store_id
  end
end
