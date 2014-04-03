class CreateSalaryDetails < ActiveRecord::Migration
  def change
    create_table :salary_details do |t|
      t.integer :current_day  #年月日
      t.decimal :deduct_num,:precision=>"6,2",:default=>0   #扣款
      t.decimal :reward_num,:precision=>"6,2",:default=>0   #奖励
      t.float :satisfied_perc  #满意度
      t.integer :staff_id

      t.datetime :created_at
    end

    add_index :salary_details, :current_day
    add_index :salary_details, :staff_id
    add_index :salary_details, :voilation_reward_id
  end
end
