class CreateSalaries < ActiveRecord::Migration
  def change
    create_table :salaries do |t|
      t.decimal :deduct_num,:precision=>"20,2",:default=>0
      t.decimal :reward_num,:precision=>"20,2",:default=>0
      t.decimal :total,:precision=>"20,2",:default=>0
      t.integer :current_month  #年月
      t.integer :staff_id 
      t.integer :satisfied_perc  #满意程度
      t.boolean :status, :default => 0
      t.decimal :reward_fee,:precision=>"20,2",:default=>0
      t.decimal :secure_fee,:precision=>"20,2",:default=>0
      t.decimal :voilate_fee,:precision=>"20,2",:default=>0
      t.datetime :created_at
      t.decimal :fact_fee, :precision=>"20,2",:default=>0
      t.decimal :work_fee, :precision=>"20,2",:default=>0
      t.decimal :manage_fee, :precision=>"20,2",:default=>0
      t.decimal :tax_fee, :precision=>"20,2",:default=>0
      t.boolean :is_edited, :defalut=>false
      t.decimal :base_salary,:precision=>"20,2",:default=>0
    end

    add_index :salaries, :current_month
    add_index :salaries, :staff_id
    add_index :salaries, :status
  end
end
