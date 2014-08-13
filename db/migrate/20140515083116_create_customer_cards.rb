class CreateCustomerCards < ActiveRecord::Migration
  def change
    create_table :customer_cards do |t|
      t.integer :customer_id
      t.integer :types
      t.integer :status
      t.integer :card_id
      t.decimal :amt, :default =>0, :precision => 16, :scale => 2  #储值卡余额
      t.string :package_content   #套餐卡项目与次数
      t.decimal :discount, :default =>0, :precision => 16, :scale => 2
      t.datetime :ended_at
      t.timestamps
    end
  end
end
