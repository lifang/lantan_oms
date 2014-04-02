class CreateCarNums < ActiveRecord::Migration
  def change
    create_table :car_nums do |t|
      t.string :num
      t.integer :car_model_id
      t.integer :buy_year
      t.integer :distance, :default => 0 #行驶里程
      t.timestamps
    end

    add_index :car_nums, :num
    add_index :car_nums, :car_model_id
  end
end
