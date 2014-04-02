class CreateSalaries < ActiveRecord::Migration
  def change
    create_table :salaries do |t|
      t.float :deduct_num
      t.float :reward_num
      t.float :total
      t.integer :current_month  #年月
      t.integer :staff_id 
      t.integer :satisfied_perc  #满意程度
      t.boolean :status, :default => 0
      t.float :reward_fee, :default=>0
      t.float :secure_fee, :default=>0
      t.float :voilate_fee, :default=>0
      t.float :fact_fee, :default=>0
      t.float :work_fee, :default=>0
      t.float :manage_fee, :default=>0
      t.float :tax_fee, :default=>0
      t.boolean :is_edited, :defalut=>false
      t.float :base_salary, :default=>0
      t.timestamps
    end

    add_index :salaries, :current_month
    add_index :salaries, :staff_id
    add_index :salaries, :status
  end
end
